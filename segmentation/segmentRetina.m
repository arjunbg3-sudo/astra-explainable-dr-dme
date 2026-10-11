function a=segmentRetina(I)
% SEGMENTRETINA Classical, explainable structural/lesion candidate module.
% This is a candidate generator. For clinical-grade masks, train/validate
% U-Net on DRIVE/CHASE-DB1 and lesion segmentation on IDRiD.

I=im2uint8(I);
G=im2double(rgb2gray(I));
R=im2double(I(:,:,1)); B=im2double(I(:,:,3));
Hsv=rgb2hsv(I); S=Hsv(:,:,2); V=Hsv(:,:,3);

% Retinal FOV.
fov=G>graythresh(G)*0.5;
fov=imclose(fov,strel("disk",12));
fov=imfill(fov,"holes");
fov=bwareafilt(fov,1);

% Optic disc: bright compact region, excluding border.
bright=V>prctile(V(fov),99.3);
bright=bright & fov;
bright=bwareaopen(bright,max(50,round(numel(G)*0.0002)));
stats=regionprops(bright,"Area","Centroid","EquivDiameter","Circularity");
if isempty(stats)
    dc=[size(G,2)/2 size(G,1)/2]; dr=min(size(G))/12;
else
    [~,k]=max([stats.Area].*[stats.Circularity]);
    dc=stats(k).Centroid; dr=stats(k).EquivDiameter/2;
end
discMask=(((1:size(G,2))-dc(1)).^2 + ...
          ((1:size(G,1))'-dc(2)).^2) <= (1.15*dr)^2;

% Fovea estimate: dark point temporal to optic disc.
offset=2.4*dr;
fc=[min(size(G,2)-1,max(1,dc(1)+offset)),dc(2)];
foveaMask=(((1:size(G,2))-fc(1)).^2 + ...
          ((1:size(G,1))'-fc(2)).^2) <= (0.18*dr)^2;

% Vessel candidate: green-channel local darkness with morphology.
green=im2double(I(:,:,2));
bg=imgaussfilt(green,7);
vessel=mat2gray(bg-green)>0.16;
vessel=imopen(vessel,strel("disk",1));
vessel=bwareaopen(vessel,max(8,round(numel(G)*0.00001)));
vessel=vessel & fov & ~discMask;

% Dark red lesions: microaneurysm/hemorrhage candidates.
dark=mat2gray(imgaussfilt(R,1)-imgaussfilt(R,5));
ma=dark>graythresh(dark)*1.15 & ~discMask & foveaMask==0 & fov;
ma=bwareaopen(ma,max(3,round(numel(G)*0.000002)));

% Bright exudate candidates.
ex=mat2gray(imgaussfilt(V,1)-imgaussfilt(V,7));
ex=ex>0.55 & S<0.55 & ~discMask & fov;
ex=bwareaopen(ex,max(8,round(numel(G)*0.00001)));

% Hemorrhage: dark, red-dominant connected components.
he=(R<prctile(R(fov),12)) & (R>1.05*B) & ~discMask & fov;
he=bwareaopen(he,max(6,round(numel(G)*0.00001)));

lesion=ma|ex|he;
stats=regionprops(lesion,"BoundingBox","Area","Centroid");
boxes=reshape([stats.BoundingBox],4,[])';

% NV cue: peripapillary vessel density higher/irregularity.
ring=imdilate(discMask,strel("disk",max(2,round(dr*0.5)))) & ~discMask;
ringArea=nnz(ring);
nvScore=nnz(vessel&ring)/max(1,ringArea);
nv=nvScore>0.18;

a=struct("fovMask",fov,"discCenter",dc,"discRadius",dr, ...
    "discMask",discMask,"foveaCenter",fc,"foveaMask",foveaMask, ...
    "vesselMask",vessel,"microaneurysmMask",ma,"exudateMask",ex, ...
    "hemorrhageMask",he,"lesionMask",lesion,"lesionBoxes",boxes, ...
    "neovascularizationCue",nv,"neovascularizationScore",nvScore, ...
    "exudateFraction",nnz(ex)/numel(ex));
end
