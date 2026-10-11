function [trainT,valT,testT]=splitManifest(M,seed)
% SPLITMANIFEST Patient/image-level stratified split.
if nargin<2, seed=42; end
rng(seed);
N=height(M); idx=(1:N)';
train=[]; val=[]; test=[];
for g=0:4
    q=idx(M.drGrade==g); q=q(randperm(numel(q)));
    n=numel(q); ntr=floor(.70*n); nv=floor(.15*n);
    train=[train;q(1:ntr)]; %#ok<AGROW>
    val=[val;q(ntr+1:ntr+nv)]; %#ok<AGROW>
    test=[test;q(ntr+nv+1:end)]; %#ok<AGROW>
end
trainT=M(train,:); valT=M(val,:); testT=M(test,:);
end
