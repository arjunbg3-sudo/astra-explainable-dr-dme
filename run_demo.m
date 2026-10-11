function result = run_demo()
% RUN_DEMO End-to-end executable demonstration.
%
% If a trained model exists at models/multitask_resnet50.mat, it is used.
% Otherwise the pipeline runs in safe prototype/demo mode.

setupProject();
root = fileparts(mfilename('fullpath'));
outDir = fullfile(root,"outputs");
if ~exist(outDir,"dir"), mkdir(outDir); end

% Generate a reproducible synthetic fundus-like image so the software can
% be tested immediately without redistributing a clinical dataset.
I = makeDemoFundus(768,768,17);
demoFile = fullfile(outDir,"demo_fundus.png");
imwrite(I,demoFile);

[result,overlay] = dr_screen(I, ...
    "ModelFile",fullfile(root,"models","multitask_resnet50.mat"), ...
    "OutputDir",outDir, ...
    "PatientID","DEMO-001");

imwrite(overlay,fullfile(outDir,"demo_overlay.png"));
save(fullfile(outDir,"demo_result.mat"),"result");

generateReport(result,overlay,fullfile(outDir,"demo_report.pdf"));

sim = runDistrictSimulation();
writetable(sim.summary,fullfile(outDir,"simulation_results.csv"));
if isfield(sim,"figure") && isgraphics(sim.figure)
    exportgraphics(sim.figure,fullfile(outDir,"simulation_bottleneck.png"),"Resolution",150);
end

fprintf("\nDemo complete.\n");
fprintf("IQA: %s (sharpness %.2f, exposure %.2f)\n", ...
    result.iqa.status,result.iqa.sharpness,result.iqa.exposureScore);
fprintf("DR: %s | referable=%d | confidence=%.3f | mode=%s\n", ...
    result.dr.label,result.dr.referable,result.dr.confidence,result.modelMode);
fprintf("Outputs: %s\n",outDir);
end
