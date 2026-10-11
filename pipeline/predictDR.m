function result = predictDR(imagePath)
%PREDICTDR Predict diabetic retinopathy grade for one fundus image.

modelFile = fullfile("outputs","DR_ResNet50","DR_ResNet50_APTOS.mat");

S = load(modelFile,"net");
net = S.net;

% APTOS class order
classNames = categorical( ...
    ["NoDR","MildNPDR","ModerateNPDR","SevereNPDR","PDR"], ...
    ["NoDR","MildNPDR","ModerateNPDR","SevereNPDR","PDR"]);

% Read image
img = imread(imagePath);

if ndims(img) == 2
    img = repmat(img,[1 1 3]);
end

if size(img,3) > 3
    img = img(:,:,1:3);
end

% Temporary datastore
imds = imageDatastore({char(imagePath)});

% IMPORTANT:
% Let MATLAB perform the same resize/preprocessing pipeline
% used during network inference.
aug = augmentedImageDatastore([224 224 3],imds);

% Predict
scores = minibatchpredict(net,aug);

% Convert scores to label
[predictedLabel,confidence] = scores2label(scores,classNames);

predictedIdx = find(classNames == predictedLabel) - 1;

% Referable DR = Grade 2 or higher
referable = predictedIdx >= 2;

% Diagnosis text
diagnoses = [
    "No DR"
    "Mild NPDR"
    "Moderate NPDR"
    "Severe NPDR"
    "Proliferative DR"
    ];

diagnosis = diagnoses(predictedIdx+1);

% Return result structure
result.imagePath = imagePath;
result.drGrade = predictedIdx;
result.diagnosis = diagnosis;
result.referable = referable;
result.confidence = confidence;

% Display
fprintf("\n");
fprintf("============================================\n");
fprintf("DIABETIC RETINOPATHY SCREENING RESULT\n");
fprintf("============================================\n");
fprintf("Image: %s\n",imagePath);
fprintf("DR Grade: %d\n",predictedIdx);
fprintf("Diagnosis: %s\n",diagnosis);
fprintf("Referable: %s\n",string(referable));
fprintf("Confidence: %.2f%%\n",confidence*100);
fprintf("============================================\n\n");

end