function [result,overlay] = dr_screen(I,varargin)
% DR_SCREEN Integrated IQA -> preprocessing -> anatomy/lesion cues ->
% multi-task model -> explainability -> structured result.
p = inputParser;
addParameter(p,"ModelFile","",@(x)isstring(x)||ischar(x));
addParameter(p,"OutputDir",pwd,@(x)isstring(x)||ischar(x));
addParameter(p,"PatientID","UNKNOWN",@(x)isstring(x)||ischar(x));
parse(p,varargin{:});
opt=p.Results;

if ischar(I) || isstring(I)
    I=imread(I);
end
I0=I;
q=iqaAssess(I);
if q.status=="Ungradable"
    result=struct("patientID",string(opt.PatientID),"iqa",q, ...
        "dr",struct("label","UNGRADABLE","grade",NaN,"referable",NaN, ...
        "confidence",NaN,"probabilities",[]), ...
        "dme",struct("positive",NaN,"confidence",NaN), ...
        "modelMode","IQA-GATE","anatomy",[]);
    overlay=I0;
    return
end

if q.status=="Borderline"
    I=enhanceFundus(I);
end

anat=segmentRetina(I);
modelMode="HEURISTIC-DEMO";
dr=struct(); dme=struct(); cam=[];

modelFile=string(opt.ModelFile);
if strlength(modelFile)>0 && isfile(modelFile)
    S=load(modelFile);
    if isfield(S,"net")
        try
            [dr,dme,cam]=predictMultiTask(S.net,I,anat);
            modelMode="TRAINED-MULTITASK";
        catch ME
            warning("Trained model could not be evaluated: %s. Using demo fallback.",ME.message);
        end
    end
end

if modelMode=="HEURISTIC-DEMO"
    [dr,dme,cam]=heuristicDemoClassifier(I,anat);
end

result=struct("patientID",string(opt.PatientID),"iqa",q, ...
    "dr",dr,"dme",dme,"modelMode",modelMode,"anatomy",anat, ...
    "timestamp",datetime("now"));

overlay=makeOverlay(I,anat,cam,dr);

if ~exist(opt.OutputDir,"dir"), mkdir(opt.OutputDir); end
end

function [dr,dme,cam]=heuristicDemoClassifier(I,a)
% Safe deterministic fallback only for software demonstration.
% It is NOT a clinical DR classifier.
G=im2double(rgb2gray(I));
lesionFrac=nnz(a.lesionMask)/numel(a.lesionMask);
redDark=mean(G(a.hemorrhageMask|a.microaneurysmMask),"all","omitnan");
if isnan(redDark), redDark=0.5; end
severity=min(4,round(4*min(1,12*lesionFrac + 0.4*(0.5-redDark))));
probs=zeros(1,5); probs(severity+1)=0.75;
probs=max(probs,0.25/4); probs=probs/sum(probs);
referable=severity>=2;
dr=struct("grade",severity,"label",severityLabel(severity), ...
    "referable",referable,"confidence",max(probs),"probabilities",probs);
dmePos=a.exudateFraction>0.002;
dme=struct("positive",dmePos,"confidence",0.65+0.3*dmePos);
cam=mat2gray(a.lesionMask + 0.5*a.vesselMask);
end

function [dr,dme,cam]=predictMultiTask(net,I,~)
% Predict with a trained multi-output dlnetwork.
X=single(imresize(I,[224 224]));
X=dlarray(X,"SSC");
[yp,yd]=predict(net,X);
if isa(yp,"dlarray"), yp=extractdata(yp); end
if isa(yd,"dlarray"), yd=extractdata(yd); end
yp=squeeze(yp); yd=squeeze(yd);
yp=yp(:)'; yd=yd(:)';
[conf,idx]=max(yp);
grade=idx-1;
dr=struct("grade",grade,"label",severityLabel(grade), ...
    "referable",grade>=2,"confidence",conf,"probabilities",yp);
dme=struct("positive",yd(1)>=0.5,"confidence",max(yd(1),1-yd(1)));
cam=[]; % replace with makeGradCAM in explainability stage
end

function s=severityLabel(g)
names=["No DR","Mild NPDR","Moderate NPDR","Severe NPDR","Proliferative DR"];
s=names(g+1);
end

function O=makeOverlay(I,a,cam,dr)
O=im2uint8(I);
if ~isempty(cam)
    cm=imresize(cam,[size(O,1),size(O,2)]);
    cm=uint8(255*mat2gray(cm));
    O(:,:,1)=uint8(0.55*double(O(:,:,1))+0.45*double(cm));
else
    m=a.lesionMask;
    O(:,:,1)=uint8(min(255,double(O(:,:,1))+110*double(m)));
end
% Vessel edges.
E=edge(a.vesselMask,"Canny");
O(:,:,2)=uint8(min(255,double(O(:,:,2))+120*double(E)));
% Disc circle approximation.
if all(isfinite(a.discCenter))
    O=insertShape(O,"Circle",[a.discCenter a.discRadius], ...
        "Color","yellow","LineWidth",3);
end
O=insertText(O,[10 10],sprintf("DR: %s | Ref: %d",dr.label,dr.referable), ...
    "BoxOpacity",0.65,"FontSize",18);
end
