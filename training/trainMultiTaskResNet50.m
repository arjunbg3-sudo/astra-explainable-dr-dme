function net= trainMultiTaskResNet50(M,varargin)
% TRAINMULTITASKRESNET50 Shared ResNet-50 encoder + DR/DME heads.
%
% M: table with imagePath, drGrade, dme.
% Requires Deep Learning Toolbox. R2024a+ is recommended.
%
% This script intentionally uses a custom training loop so weighted
% multi-task losses can be controlled explicitly.

p=inputParser;
addParameter(p,"Epochs",8,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,"MiniBatchSize",16,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,"LearnRate",1e-4,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,"OutputFile","models/multitask_resnet50.mat",@(x)ischar(x)||isstring(x));
parse(p,varargin{:}); o=p.Results;

assert(exist("dlnetwork","class")==8 || exist("dlnetwork","file")~=0, ...
    "Deep Learning Toolbox is required.");

% Build a pretrained ResNet-50 feature extractor.
if exist("imagePretrainedNetwork","file")
    base=imagePretrainedNetwork("resnet50");
    lg=layerGraph(base);
else
    lg=layerGraph(resnet50);
end

% Remove ImageNet classifier layers by name where available.
removeNames=intersect(["fc1000","fc1000_softmax","ClassificationLayer_fc1000"], ...
    string({lg.Layers.Name}));
if ~isempty(removeNames)
    lg=removeLayers(lg,cellstr(removeNames));
end

% Find the remaining global average pooling output.
names=string({lg.Layers.Name});
cand=names(contains(lower(names),"avgpool") | contains(lower(names),"pool5"));
assert(~isempty(cand),"Could not locate ResNet pooling layer.");
featureLayer=cand(end);

head=[fullyConnectedLayer(5,"Name","dr_fc")
      softmaxLayer("Name","dr_softmax")];
dmeHead=[fullyConnectedLayer(1,"Name","dme_fc")
         sigmoidLayer("Name","dme_sigmoid")];
lg=addLayers(lg,head);
lg=addLayers(lg,dmeHead);
lg=connectLayers(lg,featureLayer,"dr_fc");
lg=connectLayers(lg,featureLayer,"dme_fc");

net=dlnetwork(lg,OutputNames=["dr_softmax","dme_sigmoid"]);

% Class weights from training labels.
counts=histcounts(M.drGrade, -0.5:1:4.5);
w=mean(counts)./max(counts,1);
w=w/sum(w)*5;

avgGrad=[]; avgSqGrad=[];
N=height(M);
iteration=0;
for epoch=1:o.Epochs
    idx=randperm(N);
    running=0;
    for s=1:o.MiniBatchSize:N
        b=idx(s:min(s+o.MiniBatchSize-1,N));
        [X,Tdr,Tdme]=makeBatch(M,b);
        [loss,grads]=dlfeval(@modelLoss,net,X,Tdr,Tdme,w);
        iteration=iteration+1;
        [net,avgGrad,avgSqGrad]=adamupdate(net,grads,avgGrad,avgSqGrad, ...
            iteration, o.LearnRate);
        running=running+double(gather(extractdata(loss)));
    end
    fprintf("Epoch %d/%d loss=%.5f\n",epoch,o.Epochs,running/ceil(N/o.MiniBatchSize));
end

out=o.OutputFile;
if ~exist(fileparts(out),"dir"), mkdir(fileparts(out)); end
save(out,"net","featureLayer","w","-v7.3");
fprintf("Saved trained model to %s\n",out);
end

function [X,Tdr,Tdme]=makeBatch(M,idx)
sz=[224 224 3 numel(idx)];
X=zeros(sz,"single"); Tdr=zeros(5,numel(idx),"single"); Tdme=zeros(1,numel(idx),"single");
for k=1:numel(idx)
    I=imread(M.imagePath(idx(k)));
    if size(I,3)==1, I=repmat(I,1,1,3); end
    I=imresize(I,[224 224]);
    I=single(I)/255;
    % Field-camera augmentation.
    if rand<0.5, I=fliplr(I); end
    if rand<0.4, I=imrotate(I,(rand*10-5),"bilinear","crop"); end
    X(:,:,:,k)=I;
    Tdr(M.drGrade(idx(k))+1,k)=1;
    Tdme(1,k)=M.dme(idx(k));
end
X=dlarray(X,"SSCB"); Tdr=dlarray(Tdr,"CB"); Tdme=dlarray(Tdme,"CB");
end

function [loss,gradients]=modelLoss(net,X,Tdr,Tdme,w)
[yp,yd]=forward(net,X,"Outputs",["dr_softmax","dme_sigmoid"]);
yp=max(min(yp,1-eps),eps); yd=max(min(yd,1-eps),eps);

% Weighted categorical cross entropy.
cw=dlarray(single(w(:)),"CB");
weighted=-sum(Tdr.*log(yp).*cw,1);
drLoss=mean(weighted);

dmeLoss=-mean(Tdme.*log(yd)+(1-Tdme).*log(1-yd));
loss=0.8*drLoss+0.2*dmeLoss;
gradients=dlgradient(loss,net.Learnables);
end
