function q = iqaAssess(I)
% IQAASSESS Assess fundus gradability using focus, exposure and FOV cues.
%
% Outputs Gradable / Borderline / Ungradable plus technician feedback.
% Thresholds are intentionally configurable and must be calibrated against
% human gradability labels for a deployment camera.

if size(I,3)==1, I = repmat(I,1,1,3); end
G = im2double(rgb2gray(I));

% Focus: variance of Laplacian.
h = fspecial("laplacian",0.2);
lap = imfilter(G,h,"replicate");
sharp = var(lap(:));

% Exposure: avoid both saturation and crushed shadows.
p1 = prctile(G(:),1);
p99 = prctile(G(:),99);
p5 = prctile(G(:),5);
p95 = prctile(G(:),95);
sat = mean(G(:)>0.98);
dark = mean(G(:)<0.02);

% Field-of-view: fundus occupies a sufficiently large, roughly circular ROI.
R = mat2gray(G);
mask = R > graythresh(R)*0.55;
mask = imclose(mask,strel("disk",15));
mask = imfill(mask,"holes");
mask = bwareafilt(mask,1);
fov = nnz(mask)/numel(mask);

% Normalize component scores.
focusScore = min(1,max(0,(sharp-2e-4)/(3e-3-2e-4)));
exposureScore = 1 - min(1, 2*max(sat,dark));
fovScore = min(1,max(0,(fov-0.15)/(0.65-0.15)));

score = 0.45*focusScore + 0.35*exposureScore + 0.20*fovScore;

if focusScore < 0.20 || exposureScore < 0.20 || fovScore < 0.10
    status = "Ungradable";
    feedback = "Recapture: improve focus, illumination, and/or retinal field of view.";
elseif score < 0.55
    status = "Borderline";
    feedback = "Borderline image: enhancement applied; recapture if artifacts remain.";
else
    status = "Gradable";
    feedback = "Image acceptable for automated screening.";
end

q = struct("status",status,"score",score,"sharpness",sharp, ...
    "focusScore",focusScore,"exposureScore",exposureScore, ...
    "fieldOfViewScore",fovScore,"p1",p1,"p99",p99, ...
    "satFrac",sat,"darkFrac",dark,"feedback",feedback);
end
