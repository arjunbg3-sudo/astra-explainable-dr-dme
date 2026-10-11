function J = enhanceFundus(I)
% ENHANCEFUNDUS Illumination normalization + CLAHE + mild denoising.
I = im2uint8(I);
if size(I,3)==1, I = repmat(I,1,1,3); end

lab = rgb2lab(I);
L = lab(:,:,1)/100;
L = adapthisteq(L,"ClipLimit",0.015,"NumTiles",[8 8]);
% Smooth the illumination field and divide in luminance space.
illum = imgaussfilt(L,25);
Ln = mat2gray(L ./ max(illum,eps));
lab(:,:,1) = 100*Ln;
J = lab2rgb(lab,"ColorSpace","adobe-rgb-1998");
J = im2uint8(J);
J = imbilatfilt(J,12,3);
end
