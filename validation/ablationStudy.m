function A=ablationStudy(yTrue,scoreClassifier,scoreGrounded,scoreFull)
% ABLATIONSTUDY Compare classifier-only, classifier+segmentation, full model.
% Scores are probabilities for referable DR on the same locked test set.
scores={scoreClassifier,scoreGrounded,scoreFull};
names=["Classifier-only","Classifier + segmentation","Full multi-task pipeline"];
A=table('Size',[3 3],"VariableTypes",["string","double","double"], ...
    "VariableNames",["Model","Sensitivity","Specificity"]);
for k=1:3
    y=double(yTrue(:)>=2); pred=scores{k}>=0.5;
    A.Model(k)=names(k);
    A.Sensitivity(k)=sum(pred&y)/max(1,sum(y));
    A.Specificity(k)=sum(~pred&~y)/max(1,sum(~y));
end
disp(A);
end
