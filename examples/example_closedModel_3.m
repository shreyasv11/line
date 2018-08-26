model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);

jobclass{1} = ClosedClass(model, 'Class1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 0, node{1}, 0);
jobclass{3} = ClosedClass(model, 'Class3', 1, node{1}, 0);

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

% This part illustrates the execution of different solvers
solver = {};
solver{end+1} = SolverCTMC(model);
solver{end+1} = SolverJMT(model,'seed',23000,'verbose',true);
solver{end+1} = SolverSSA(model,'seed',23000,'verbose',true);
solver{end+1} = SolverFluid(model);
solver{end+1} = SolverMVA(model);
solver{end+1} = SolverNC(model,'method','exact');
solver{end+1} = SolverAuto(model);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());
    AvgTable{s} = solver{s}.getAvgTable();
    AvgByChainTable{s} = solver{s}.getAvgByChainTable();
    AvgSysByChainTable{s} = solver{s}.getAvgSysByChainTable();
    AvgTable{s}
    AvgByChainTable{s}
    AvgSysByChainTable{s}
end