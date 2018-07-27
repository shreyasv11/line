clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'ClosedClass1', 5, node{1}, 0);

node{1}.setService(jobclass{1}, Exp.fitMoments(1.0)); % service time mean = 1
node{2}.setService(jobclass{1}, Exp.fitMoments(2.0)); % service time mean = 2

model.addLink(node{1}, node{1});
model.addLink(node{1}, node{2});
model.addLink(node{2}, node{1});
model.addLink(node{2}, node{2});

node{1}.setProbRouting(jobclass{1}, node{1}, 0.7)
node{1}.setProbRouting(jobclass{1}, node{2}, 0.3)
node{2}.setProbRouting(jobclass{1}, node{1}, 1.0)

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

% This part illustrates the execution of different solvers
fprintf(1,'This example illustrates the execution of different solvers on a basic closed model.\n')


solver = {};
options = Solver.defaultOptions;
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
