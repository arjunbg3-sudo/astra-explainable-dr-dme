function model=buildSimEventsModel()
% BUILDSIMEVENTSMODEL Build a basic SimEvents PHC queue model.
% This complements runDistrictSimulation.m. Library block names can vary
% slightly between releases; failures are reported without stopping the
% rest of the project.

model="Astra_DR_District_SimEvents";
if bdIsLoaded(model), close_system(model,0); end
new_system(model); open_system(model);
try
    load_system("simeventslib");
    add_block("simeventslib/Entity Generator",model+"/PatientArrival", ...
        "Position",[50 100 180 150]);
    add_block("simeventslib/Entity Queue",model+"/ReviewQueue", ...
        "Position",[260 90 390 160]);
    add_block("simeventslib/Entity Server",model+"/RemoteReview", ...
        "Position",[470 90 610 160]);
    add_block("simeventslib/Entity Terminator",model+"/Completed", ...
        "Position",[690 100 810 150]);
    add_line(model,"PatientArrival/1","ReviewQueue/1");
    add_line(model,"ReviewQueue/1","RemoteReview/1");
    add_line(model,"RemoteReview/1","Completed/1");
    save_system(model,model+".slx");
    fprintf("Created %s.slx\n",model);
catch ME
    warning("Could not construct SimEvents model automatically: %s",ME.message);
    fprintf("Use runDistrictSimulation.m for the executable parameter sweep.\n");
end
end
