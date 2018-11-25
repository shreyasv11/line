model = Network.cyclicPs(30,[1;5]);
model.stations{2}.setNumberOfServers(3);

solver = {};
%solver{end+1} = SolverCTMC(model);
%solver{end+1} = SolverJMT(model,'method','jsim','samples',1e6);
%solver{end+1} = SolverMVA(model,'method','exact');
solver{end+1} = SolverNC(model,'method','exact');
solver{end+1} = SolverJMT(model,'method','jmva','seed',23000,'verbose',true,'keep',true);
%solver{end+1} = SolverJMT(model,'method','jmva.comom','seed',23000,'verbose',true,'keep',true);
%solver{end+1} = SolverJMT(model,'method','jmva.recal','seed',23000,'verbose',true);
solver{end+1} = SolverJMT(model,'method','jmva.ls','samples',1e4,'seed',23000,'verbose',true,'keep',true);

AvgTable = {};
logNC = [];
for s=1:length(solver)
    fprintf(1,'SOLVER: %s METHOD: %s\n',solver{s}.getName(),solver{s}.getOptions.method);    
%    AvgTable = solver{s}.getAvgTable
    logNC(end+1,1) = solver{s}.getProbNormConst
end
