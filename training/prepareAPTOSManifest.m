function M = prepareAPTOSManifest(csvFile, imageFolder)
% prepareAPTOSManifest
% Converts the APTOS 2019 train.csv format into the standardized
% manifest used by the Astra DR project.
%
% APTOS provides:
%   id_code
%   diagnosis (0..4)
%
% APTOS does NOT provide DME labels, so dme is set to NaN.
%
% Example:
%   M = prepareAPTOSManifest( ...
%       "data/APTOS/train.csv", ...
%       "data/APTOS/train_images");

arguments
    csvFile (1,1) string
    imageFolder (1,1) string
end

fprintf("\nPreparing APTOS manifest...\n");

% Read APTOS CSV
T = readtable(csvFile, "TextType", "string");

% Check required columns
required = ["id_code", "diagnosis"];

if ~all(ismember(required, string(T.Properties.VariableNames)))
    error("APTOS CSV must contain id_code and diagnosis columns.");
end

% Number of images
N = height(T);

% Allocate output
imagePath = strings(N,1);
drGrade = zeros(N,1);

% Build image paths
for i = 1:N

    id = string(T.id_code(i));

    % APTOS training images are PNG files
    p = fullfile(imageFolder, id + ".png");

    imagePath(i) = p;
    drGrade(i) = double(T.diagnosis(i));

end

% Validate DR labels
if any(~ismember(drGrade, 0:4))
    error("APTOS diagnosis values must be integers from 0 to 4.");
end

% APTOS has no DME annotation
dme = nan(N,1);

% Create standardized manifest
M = table( ...
    imagePath, ...
    drGrade, ...
    dme, ...
    T.id_code, ...
    'VariableNames', ...
    {'imagePath','drGrade','dme','id_code'});

% Check files
exists = isfile(M.imagePath);

fprintf("APTOS images listed: %d\n", N);
fprintf("Image files found:   %d\n", sum(exists));
fprintf("Missing images:      %d\n", sum(~exists));

if any(~exists)
    warning("%d image files could not be found.", sum(~exists));
end

% Display class distribution
fprintf("\nDR class distribution:\n");
disp(groupsummary(M, "drGrade"));

% Save standardized manifest
outputFile = fullfile(fileparts(csvFile), "APTOS_manifest.csv");

writetable(M, outputFile);

fprintf("\nManifest saved to:\n%s\n", outputFile);

end