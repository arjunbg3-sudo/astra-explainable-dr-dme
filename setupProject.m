function setupProject()
% SETUPPROJECT Add project folders to MATLAB path and create output folders.

root = fileparts(mfilename('fullpath'));
addpath(genpath(root));

out = fullfile(root,"outputs");
if ~exist(out,"dir"), mkdir(out); end

fprintf("Astra DR+DME MATLAB project ready.\n");
fprintf("Root: %s\n",root);

% Report installed toolbox visibility without making the project fail.
products = ["Image Processing Toolbox","Computer Vision Toolbox", ...
    "Deep Learning Toolbox","Statistics and Machine Learning Toolbox", ...
    "Simulink","SimEvents"];
for p = products
    fprintf("%-40s %s\n",p, ternary(hasProduct(p),"OK","NOT DETECTED"));
end
end

function y = hasProduct(name)
v = ver;
y = any(strcmpi({v.Name},name));
end

function y = ternary(c,a,b)
if c, y=a; else, y=b; end
end
