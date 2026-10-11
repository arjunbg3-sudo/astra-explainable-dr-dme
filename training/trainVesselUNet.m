function net=trainVesselUNet(imageDir,maskDir,outFile)
% TRAINVESSELUNET Train a compact vessel segmentation network.
% imageDir and maskDir must contain paired files with matching base names.
%
% For production, use the official DRIVE/CHASE-DB1 train/test split and
% report Dice/IoU on a locked test set.

imds=imageDatastore(imageDir,"FileExtensions",{".png",".jpg",".jpeg",".tif",".tiff"});
pxds=imageDatastore(maskDir,"FileExtensions",{".png",".jpg",".jpeg",".tif",".tiff"});

% Two classes: background / vessel.
classes=["background","vessel"];
labelIDs=[0 255];
px= pixelLabelDatastore(pxds.Files,classes,labelIDs);
assert(numel(imds.Files)==numel(px.Files),"Image/mask counts differ.");

inputSize=[256 256 3];
if exist("unetLayers","file")
    layers=unetLayers(inputSize,2);
    opts=trainingOptions("adam","InitialLearnRate",1e-4, ...
        "MaxEpochs",30,"MiniBatchSize",8,"Shuffle","every-epoch", ...
        "Plots","training-progress","Verbose",true);
    ds=pixelLabelImageDatastore(imds,px,"OutputSize",inputSize(1:2));
    net=trainNetwork(ds,layers,opts);
else
    error("unetLayers is unavailable in this MATLAB release.");
end
if nargin>=3 && ~isempty(outFile)
    save(outFile,"net","-v7.3");
end
end
