function cal=calibrateThresholds(yTrue,refScore)
% CALIBRATETHRESHOLDS Select a referable-DR threshold on validation data.
% The operating point maximizes sensitivity while requiring specificity
% >= 0.85 where possible. This threshold must be frozen before test use.

y=double(yTrue(:)>=2); s=double(refScore(:));
[fpr,tpr,thr,auc]=perfcurve(y,s,1);
spec=1-fpr;
ok=find(spec>=0.85);
if isempty(ok)
    [~,k]=max(tpr); 
else
    [~,kk]=max(tpr(ok)); k=ok(kk);
end
cal=struct("threshold",thr(k),"sensitivity",tpr(k),"specificity",spec(k),"AUC",auc);
fprintf("Validation threshold %.4f | sens %.3f | spec %.3f | AUC %.3f\n", ...
    cal.threshold,cal.sensitivity,cal.specificity,cal.AUC);
end
