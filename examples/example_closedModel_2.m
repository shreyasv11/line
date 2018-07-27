clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.FCFS);
node{2}.setNumServers(2);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'ClosedClass1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'ClosedClass2', 2, node{1}, 0);

node{1}.setService(jobclass{1}, Erlang(3,2));
node{1}.setService(jobclass{2}, HyperExp(0.5,3.0,10.0));

node{2}.setService(jobclass{1}, HyperExp(0.1,1.0,10.0));
node{2}.setService(jobclass{2}, Exp(1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = cell(K,K);
P{1,1} = [0.3,0.1;
    0.2,0];
P{1,2} = [0.6,0;
    0.8,0];
P{2,2} = [0,1  ;
    0,0];
P{2,1} = [0,0  ;
    1,0];

model.linkNetwork(P);
%%
options = Solver.defaultOptions;
options.keep=true;
options.verbose=1;
options.samples=5e3;
disp('This example shows the execution of the solver on a 2-class 2-node class-switching model.')
% This part illustrates the execution of different solvers
solver={};
solver{end+1} = SolverCTMC(model,options);
solver{end+1} = SolverJMT(model,options);
solver{end+1} = SolverSSA(model,options);
solver{end+1} = SolverFluid(model,options);
solver{end+1} = SolverAMVA(model,options);
solver{end+1} = SolverNC(model,options);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());
    AvgTable = solver{s}.getAvgTable()
end
