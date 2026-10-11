function generateReport(result,overlay,outFile)
% GENERATEREPORT Create a clinician-facing PDF/PNG research report.
if nargin<3, outFile="DR_screening_report.pdf"; end
outFile=char(outFile);
[folder,base,ext]=fileparts(outFile);
if isempty(folder), folder=pwd; end
if ~exist(folder,"dir"), mkdir(folder); end

fig=figure("Visible","off","Color","w","Position",[100 100 1200 850]);
tiledlayout(2,2,"Padding","compact","TileSpacing","compact");

nexttile; imshow(overlay); title("Evidence / anatomy overlay");
nexttile;
axis off;
text(0,0.95,"AUTOMATED DR+DME SCREENING — RESEARCH PROTOTYPE", ...
    "FontSize",16,"FontWeight","bold");
text(0,0.82,sprintf("Patient: %s",result.patientID),"FontSize",12);
text(0,0.74,sprintf("IQA: %s",result.iqa.status),"FontSize",12);
text(0,0.66,sprintf("DR: %s",result.dr.label),"FontSize",12);
text(0,0.58,sprintf("Referable (Level 2+): %d",result.dr.referable),"FontSize",12);
text(0,0.50,sprintf("DR confidence: %.3f",result.dr.confidence),"FontSize",12);
text(0,0.42,sprintf("DME positive: %d",result.dme.positive),"FontSize",12);
text(0,0.34,sprintf("DME confidence: %.3f",result.dme.confidence),"FontSize",12);
text(0,0.22,"Human review required before clinical action.","FontSize",11);
text(0,0.12,"Model mode: "+string(result.modelMode),"FontSize",10);

nexttile; imshow(result.anatomy.vesselMask); title("Vessel candidate map");
nexttile; imshow(result.anatomy.lesionMask); title("Lesion candidate mask");

if strcmpi(ext,".pdf")
    exportgraphics(fig,outFile,"ContentType","vector");
else
    exportgraphics(fig,fullfile(folder,base+".png"),"Resolution",160);
end
close(fig);
end
