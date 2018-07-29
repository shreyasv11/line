fprintf(1,'This example illustrates the execution on a layered queueing network model.\n')
fprintf(1,'Performance indexes now refer to processors, tasks, entries, and activities.\n')
fprintf(1,'Indexes refer to the submodel (layer) where the processor or task acts as a server.\n')
fprintf(1,'NaN indexes indicate that the metric is not supported by the node type.\n')

cwd = fileparts(which(mfilename));
model = LayeredNetwork.parseXML([cwd,filesep,'example_layeredModel_4.xml']);

options = SolverLQNS.defaultOptions;
options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

s = SolverLQNS(model);
avgTable = s.getAvgTable()

useLQNSnaming = true;
avgTable = s.getAvgTable(useLQNSnaming)

fprintf(1,'List of submodels (layers), the second station is the processor or task acting as a server within that submodel:\n')
for e=1:model.getNumberOfLayers
    fprintf(1,'Submodel (layer) %d:\n',e)
    model.ensemble{e}.getStationNames
end
