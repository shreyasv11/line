clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);
node{3} = QueueingStation(model, 'Queue2', SchedStrategy.PS);


jobclass{1} = ClosedClass(model, 'Class1', 1, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 1, node{1}, 0);

node{1}.setService(jobclass{1}, Erlang(3,2));
node{1}.setService(jobclass{2}, HyperExp(0.5,3.0,10.0));

node{2}.setService(jobclass{1}, HyperExp(0.1,1.0,10.0));
node{2}.setService(jobclass{2}, MMPP2(1,2,3,4));
%node{2}.setService(jobclass{2}, Exp(2));

node{3}.setService(jobclass{1}, HyperExp(0.1,1.0,10.0));
node{3}.setService(jobclass{2}, Erlang(1,2));

model.addLink(node{1}, node{1});
model.addLink(node{1}, node{2});
model.addLink(node{1}, node{3});
model.addLink(node{2}, node{1});
model.addLink(node{3}, node{1});

node{1}.setProbRouting(jobclass{1}, node{1}, 0.0)
node{1}.setProbRouting(jobclass{1}, node{2}, 0.3)
node{1}.setProbRouting(jobclass{1}, node{3}, 0.7)
node{2}.setProbRouting(jobclass{1}, node{1}, 1.0)
node{3}.setProbRouting(jobclass{1}, node{1}, 1.0)

M = model.getNumberOfNodes;
K = model.getNumberOfClasses;
T = model.getAvgTputHandles();

solver={};
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
