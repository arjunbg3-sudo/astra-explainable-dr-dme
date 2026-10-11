function [scoreMap,overlay] = makeGradCAM(net,img,predIdx)
%NETRASCREEEN Grad-CAM explanation for DR prediction

% Ensure RGB
if ndims(img) == 2
    img = repmat(img,[1 1 3]);
end

if size(img,3) > 3
    img = img(:,:,1:3);
end

% Grad-CAM uses the network input size
inputImg = imresize(img,[224 224]);

% IMPORTANT:
% predIdx is 0-4, while MATLAB class channels are 1-5
classIdx = predIdx + 1;

% Generate Grad-CAM
scoreMap = gradCAM(net,inputImg,classIdx);

if isa(scoreMap,"dlarray")
    scoreMap = extractdata(scoreMap);
end

scoreMap = gather(scoreMap);
scoreMap = double(scoreMap);

% Normalize heatmap
scoreMap = scoreMap - min(scoreMap(:));

mx = max(scoreMap(:));

if mx > 0
    scoreMap = scoreMap ./ mx;
end

% Resize heatmap to original image
scoreMap = imresize( ...
    scoreMap, ...
    [size(img,1) size(img,2)]);

% Convert original image
overlay = im2double(img);

if size(overlay,3) == 1
    overlay = repmat(overlay,[1 1 3]);
end

% Heatmap
heatmapRGB = ind2rgb( ...
    uint8(scoreMap*255), ...
    jet(256));

% Blend
alpha = 0.45;

overlay = ...
    (1-alpha)*overlay + ...
    alpha*heatmapRGB;

overlay = min(max(overlay,0),1);

end