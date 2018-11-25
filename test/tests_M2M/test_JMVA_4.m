model = Network.cyclicPsInf([11,7],[10,5;5,9],[91,92]);

solver = {};
solver{end+1} = SolverNC(model,'method','exact');
solver{end+1} = SolverJMT(model,'method','jmva.comom','seed',23000,'verbose',true);
solver{end+1} = SolverJMT(model,'method','jmva.recal','seed',23000,'verbose',true);
solver{end+1} = SolverJMT(model,'method','jmva.ls','seed',23000,'verbose',true);

logNC=[];
for s=1:length(solver)
    fprintf(1,'SOLVER: %s METHOD: %s\n',solver{s}.getName(),solver{s}.getOptions.method);    
    logNC(end+1,1) = solver{s}.getProbNormConst
end
