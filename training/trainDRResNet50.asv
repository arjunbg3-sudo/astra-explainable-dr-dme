function results = trainDRResNet50(trainT,valT,testT)
% trainDRResNet50
% APTOS 2019 five-class diabetic retinopathy classifier.
%
% MATLAB R2026a
%
% DR classes:
%   0 = No DR
%   1 = Mild NPDR
%   2 = Moderate NPDR
%   3 = Severe NPDR
%   4 = PDR
%
% Referable DR = grades 2, 3, 4
%
% APTOS does not contain DME labels.
% This function trains the DR component only.

rng(42);

%% Configuration

inputSize = [224 224 3];
numClasses = 5;

miniBatchSize = 16;
maxEpochs = 3;
initialLearnRate = 1e-4;

outputDir = fullfile("outputs","DR_ResNet50");

if ~isfolder(outputDir)
    mkdir(outputDir);
end

fprintf("\n");
fprintf("============================================\n");
fprintf(" ASTRA DR — APTOS RESNET-50 TRAINING\n");
fprintf("============================================\n\n");

%% Convert paths to cell arrays

trainPaths = cellstr(string(trainT.imagePath));
valPaths   = cellstr(string(valT.imagePath));
testPaths  = cellstr(string(testT.imagePath));

%% Validate files

assert(all(cellfun(@isfile,trainPaths)), ...
    "One or more training images are missing.");

assert(all(cellfun(@isfile,valPaths)), ...
    "One or more validation images are missing.");

assert(all(cellfun(@isfile,testPaths)), ...
    "One or more test images are missing.");

%% Class statistics

classCounts = zeros(numClasses,1);

for c = 0:4
    classCounts(c+1) = sum(trainT.drGrade == c);
end

classWeights = sum(classCounts) ./ ...
    (numClasses .* classCounts);

classWeights = classWeights ./ mean(classWeights);

fprintf("Training distribution:\n");

disp(table( ...
    (0:4)', ...
    classCounts, ...
    classWeights, ...
    'VariableNames', ...
    {'DRGrade','Images','ClassWeight'}));

%% Load pretrained ResNet-50

fprintf("Loading pretrained ResNet-50...\n");

net = imagePretrainedNetwork( ...
    "resnet50", ...
    NumClasses=numClasses);

fprintf("ResNet-50 loaded successfully.\n");

%% Data augmentation

augmenter = imageDataAugmenter( ...
    RandXReflection=true, ...
    RandRotation=[-10 10], ...
    RandXTranslation=[-8 8], ...
    RandYTranslation=[-8 8], ...
    RandScale=[0.90 1.10]);

%% Create categorical labels

trainLabels = categorical( ...
    trainT.drGrade, ...
    0:4, ...
    ["NoDR","MildNPDR","ModerateNPDR", ...
     "SevereNPDR","PDR"]);

valLabels = categorical( ...
    valT.drGrade, ...
    0:4, ...
    ["NoDR","MildNPDR","ModerateNPDR", ...
     "SevereNPDR","PDR"]);

testLabels = categorical( ...
    testT.drGrade, ...
    0:4, ...
    ["NoDR","MildNPDR","ModerateNPDR", ...
     "SevereNPDR","PDR"]);

%% Balanced training indices

balancedIdx = createBalancedIndices(trainT.drGrade);

balancedPaths = trainPaths(balancedIdx);
balancedLabels = trainLabels(balancedIdx);

fprintf("\nOriginal training images: %d\n", ...
    numel(trainPaths));

fprintf("Balanced training samples: %d\n", ...
    numel(balancedPaths));

%% Create datastores

imdsTrain = imageDatastore( ...
    balancedPaths, ...
    Labels=balancedLabels);

imdsVal = imageDatastore( ...
    valPaths, ...
    Labels=valLabels);

imdsTest = imageDatastore( ...
    testPaths, ...
    Labels=testLabels);

%% Resize / augment

augTrain = augmentedImageDatastore( ...
    inputSize(1:2), ...
    imdsTrain, ...
    DataAugmentation=augmenter);

augVal = augmentedImageDatastore( ...
    inputSize(1:2), ...
    imdsVal);

augTest = augmentedImageDatastore( ...
    inputSize(1:2), ...
    imdsTest);

%% Training options

validationFrequency = max(1, ...
    floor(numel(balancedPaths)/miniBatchSize));

options = trainingOptions("adam", ...
    InitialLearnRate=initialLearnRate, ...
    MaxEpochs=maxEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    Shuffle="every-epoch", ...
    ValidationData=augVal, ...
    ValidationFrequency=validationFrequency, ...
    ValidationPatience=4, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.1, ...
    LearnRateDropPeriod=5, ...
    L2Regularization=1e-4, ...
    ExecutionEnvironment="cpu", ...
    OutputNetwork="best-validation", ...
    Plots="training-progress", ...
    Verbose=true);

%% Train

fprintf("\n");
fprintf("============================================\n");
fprintf(" STARTING TRAINING\n");
fprintf("============================================\n");

[net,info] = trainnet( ...
    augTrain, ...
    net, ...
    "crossentropy", ...
    options);

fprintf("\nTraining complete.\n");

%% Save model

modelFile = fullfile( ...
    outputDir, ...
    "DR_ResNet50_APTOS.mat");

save(modelFile, ...
    "net", ...
    "info", ...
    "classWeights", ...
    "classCounts", ...
    "inputSize", ...
    "-v7.3");

fprintf("\nModel saved:\n%s\n",modelFile);

%% Validation

fprintf("\nEvaluating validation set...\n");

valScores = minibatchpredict(net,augVal);

valPred = scoresToLabels(valScores);

valAccuracy = mean(valPred == valLabels);

fprintf("Validation accuracy: %.2f%%\n", ...
    100*valAccuracy);

%% Test

fprintf("\nEvaluating locked test set...\n");

testScores = minibatchpredict(net,augTest);

testPred = scoresToLabels(testScores);

testAccuracy = mean(testPred == testLabels);

fprintf("5-class test accuracy: %.2f%%\n", ...
    100*testAccuracy);

%% Confusion matrix

fig = figure( ...
    "Name","APTOS DR Confusion Matrix", ...
    "NumberTitle","off");

confusionchart(testLabels,testPred);

title("APTOS ResNet-50 — DR Test Set");

exportgraphics( ...
    fig, ...
    fullfile(outputDir,"confusion_matrix.png"), ...
    "Resolution",150);

%% Referable DR

actualNumeric = double(testT.drGrade);

predNumeric = categoricalToDRGrade(testPred);

actualReferable = actualNumeric >= 2;
predReferable = predNumeric >= 2;

TP = sum(predReferable & actualReferable);
TN = sum(~predReferable & ~actualReferable);
FP = sum(predReferable & ~actualReferable);
FN = sum(~predReferable & actualReferable);

sensitivity = TP / max(TP + FN,1);
specificity = TN / max(TN + FP,1);

precision = TP / max(TP + FP,1);
NPV = TN / max(TN + FN,1);

%% Results

fprintf("\n");
fprintf("============================================\n");
fprintf(" REFERABLE DR RESULTS\n");
fprintf("============================================\n");

fprintf("TP = %d\n",TP);
fprintf("TN = %d\n",TN);
fprintf("FP = %d\n",FP);
fprintf("FN = %d\n\n",FN);

fprintf("Sensitivity = %.4f (%.2f%%)\n", ...
    sensitivity,100*sensitivity);

fprintf("Specificity = %.4f (%.2f%%)\n", ...
    specificity,100*specificity);

fprintf("Precision   = %.4f (%.2f%%)\n", ...
    precision,100*precision);

fprintf("NPV         = %.4f (%.2f%%)\n", ...
    NPV,100*NPV);

%% Save results

results = struct();

results.model = "ResNet-50";
results.dataset = "APTOS 2019";

results.trainN = height(trainT);
results.validationN = height(valT);
results.testN = height(testT);

results.validationAccuracy = valAccuracy;
results.testAccuracy = testAccuracy;

results.classCounts = classCounts;
results.classWeights = classWeights;

results.referable.TP = TP;
results.referable.TN = TN;
results.referable.FP = FP;
results.referable.FN = FN;

results.referable.sensitivity = sensitivity;
results.referable.specificity = specificity;
results.referable.precision = precision;
results.referable.NPV = NPV;

save( ...
    fullfile(outputDir,"test_results.mat"), ...
    "results");

fprintf("\nResults saved to:\n%s\n", ...
    fullfile(outputDir,"test_results.mat"));

fprintf("\n============================================\n");
fprintf(" ASTRA DR TRAINING STAGE COMPLETE\n");
fprintf("============================================\n");

end


%% ========================================================
function idx = createBalancedIndices(labels)

classes = 0:4;

counts = zeros(5,1);

for k = 1:5
    counts(k) = sum(labels == classes(k));
end

targetCount = max(counts);

idx = [];

for k = 1:5

    classIdx = find(labels == classes(k));

    selected = classIdx( ...
        randi(numel(classIdx),targetCount,1));

    idx = [idx; selected]; %#ok<AGROW>

end

idx = idx(randperm(numel(idx)));

end


%% ========================================================
function labels = scoresToLabels(scores)

scores = extractdata(scores);

[~,idx] = max(scores,[],2);

labels = categorical( ...
    idx-1, ...
    0:4, ...
    ["NoDR","MildNPDR","ModerateNPDR", ...
     "SevereNPDR","PDR"]);

end


%% ========================================================
function grades = categoricalToDRGrade(labels)

names = string(labels);

grades = zeros(numel(names),1);

grades(names == "NoDR") = 0;
grades(names == "MildNPDR") = 1;
grades(names == "ModerateNPDR") = 2;
grades(names == "SevereNPDR") = 3;
grades(names == "PDR") = 4;

end