function metrics=evaluateReferable(yTrue,yPred,scoreRef)
% EVALUATEREFERABLE Report referable-DR and 5-class grading metrics.
%
% yTrue/yPred are ICDR grades 0..4. scoreRef is probability/score for
% referable DR (grade >=2).

yt=double(yTrue(:)); yp=double(yPred(:));
ytRef=yt>=2; ypRef=yp>=2;
tp=sum(ytRef & ypRef); tn=sum(~ytRef & ~ypRef);
fp=sum(~ytRef & ypRef); fn=sum(ytRef & ~ypRef);
sens=tp/max(1,tp+fn); spec=tn/max(1,tn+fp);
ppv=tp/max(1,tp+fp); npv=tn/max(1,tn+fn);

if nargin>=3 && ~isempty(scoreRef)
    [~,~,~,auc]=perfcurve(ytRef,double(scoreRef(:)),true);
else, auc=NaN; end

% Quadratic weighted kappa for 0..4 ICDR grading.
K=5; O=zeros(K); 
for i=1:numel(yt)
    if yt(i)>=0 && yt(i)<K && yp(i)>=0 && yp(i)<K
        O(yt(i)+1,yp(i)+1)=O(yt(i)+1,yp(i)+1)+1;
    end
end
row=sum(O,2); col=sum(O,1); E=row*col/max(1,sum(O(:)));
W=zeros(K);
for i=1:K
    for j=1:K, W(i,j)=((i-j)^2)/(K-1)^2; end
end
kappa=1-sum(W.*O,'all')/max(eps,sum(W.*E,'all'));

metrics=struct("sensitivity",sens,"specificity",spec,"PPV",ppv,"NPV",npv, ...
    "AUC",auc,"TP",tp,"TN",tn,"FP",fp,"FN",fn,"quadraticWeightedKappa",kappa, ...
    "meetsTarget",sens>0.90 && spec>0.85);
end
