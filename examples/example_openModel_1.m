
clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.FCFS);
node{3} = Source(model,'Source');
node{4} = Sink(model,'Sink');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = OpenClass(model, 'OpenClass1', 0);

node{1}.setService(jobclass{1}, HyperExp(0.5,3.0,10.0));

node{2}.setService(jobclass{1}, Exp(1));

node{3}.setArrival(jobclass{1}, Exp(0.1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = cell(K,K);
P{1,1} = [0,1,0,0; 0,0,0,1; 1,0,0,0; 0,0,0,0];

model.linkNetwork(P);
%%
options = Solver.defaultOptions;
options.keep=true;
options.verbose=1;
%options.samples=2e4;

disp('This example shows the execution of the solver on a 1-class 2-node open model.')
% This part illustrates the execution of different solvers
solver={};
%solver{end+1} = SolverCTMC(model,options); % CTMC is infinite on this model
solver{end+1} = SolverJMT(model,options);
solver{end+1} = SolverSSA(model,options);
%solver{end+1} = SolverFluid(model,options);
solver{end+1} = SolverAMVA(model,options);
%solver{end+1} = SolverNC(model,options);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());
    AvgTable = solver{s}.getAvgTable()
end
