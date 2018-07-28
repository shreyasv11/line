model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'ClosedClass1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'ClosedClass2', 0, node{1}, 0);
jobclass{3} = ClosedClass(model, 'ClosedClass3', 1, node{1}, 0);

node{1}.setService(jobclass{1}, Erlang(3,2));
node{1}.setService(jobclass{2}, HyperExp(0.5,3.0,10.0));
node{1}.setService(jobclass{3}, Exp(1));

node{2}.setService(jobclass{1}, HyperExp(0.1,1.0,10.0));
node{2}.setService(jobclass{2}, Exp(2));
node{2}.setService(jobclass{3}, Exp(3));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = cell(K,K);

P{1,1} = [0.3,0.1; 0.2,0];
P{1,2} = [0.6,0; 0.8,0];
P{1,3} = zeros(M);

P{2,1} = [0,0; 1,0];
P{2,2} = [0,1; 0,0];
P{2,3} = zeros(M);

P{3,1} = zeros(M);
P{3,2} = zeros(M);
P{3,3} = circul(M);

model.linkNetwork(P);

%%
options = Solver.defaultOptions;
options.keep=true;
options.verbose=1;

solver={};
solver{end+1} = SolverCTMC(model,options);
solver{end+1} = SolverFluid(model,options);
solver{end+1} = SolverAMVA(model,options);
solver{end+1} = SolverNC(model,options);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());
    AvgTable = solver{s}.getAvgTable()
    AvgByChainTable = solver{s}.getAvgByChainTable()
    AvgSysByChainTable = solver{s}.getAvgSysByChainTable()
end

