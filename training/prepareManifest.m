function M=prepareManifest(csvFile)
% PREPAREMANIFEST Validate and standardize a labels CSV.
T=readtable(csvFile,"TextType","string");
required=["imagePath","drGrade","dme"];
assert(all(ismember(required,string(T.Properties.VariableNames))), ...
    "CSV must contain imagePath, drGrade, dme columns.");

root=fileparts(csvFile);
p=string(T.imagePath);
for i=1:height(T)
    if ~isfile(p(i)) && isfile(fullfile(root,p(i)))
        p(i)=fullfile(root,p(i));
    end
end
T.imagePath=p;
T.drGrade=double(T.drGrade);
T.dme=double(T.dme);
assert(all(ismember(T.drGrade,0:4)),"drGrade must be 0..4.");
assert(all(ismember(T.dme,[0 1])),"dme must be 0/1.");
M=T;
writetable(M,fullfile(root,"manifest_standardized.csv"));
fprintf("Manifest: %d images\n",height(M));
disp(groupsummary(M,"drGrade"));
end
