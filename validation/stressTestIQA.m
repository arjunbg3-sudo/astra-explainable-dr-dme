function T=stressTestIQA(I)
% STRESSTESTIQA Apply blur, underexposure and glare perturbations and score IQA.
variants=["original","blurred","underexposed","glare"];
imgs=cell(4,1); imgs{1}=I;
imgs{2}=imgaussfilt(I,3);
imgs{3}=uint8(double(I)*0.45);
J=I; m=false(size(I,1),size(I,2)); [x,y]=meshgrid(1:size(I,2),1:size(I,1));
m=(x-size(I,2)*0.72).^2+(y-size(I,1)*0.28).^2<(min(size(I))*0.18)^2;
for c=1:3, tmp=J(:,:,c); tmp(m)=255; J(:,:,c)=tmp; end
imgs{4}=J;
rows=zeros(4,5);
for k=1:4
    q=iqaAssess(imgs{k});
    rows(k,:)=[q.score q.sharpness q.focusScore q.exposureScore q.fieldOfViewScore];
end
T=array2table(rows,"VariableNames",["score","sharpness","focusScore","exposureScore","fovScore"], ...
    "RowNames",cellstr(variants));
disp(T);
end
