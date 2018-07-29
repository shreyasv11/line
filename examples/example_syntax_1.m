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
node{2}.setService(jobclass{2}, Exp(1));
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

fprintf(1,'This example shows how to solve only for selected performance indexes.\n');

solver={};
options = Solver.defaultOptions;
solver = SolverJMT(model,options);

T = model.getAvgTputHandles();

tic;
[QN,UN,RN,TN] = solver.getAvg([],[],[],T)
toc;

% without parameters, all performance indexes are requested automatically
tic;
[QN,UN,RN,TN] = solver.getAvg()
toc;

% value is now cached
tic;
[QN,UN,RN,TN] = solver.getAvg([],[],[],T)
toc;

% we can also solve the model for selective metrics
tic;
[TN] = solver.getAvgTput()
toc;

% this is going to return the handle automatically created during the
% earlier getAvg() call and internally stored
Q = model.getAvgQLenHandles();

% value is now cached also for the other handles
tic;
[QN,UN,RN,TN] = solver.getAvg(Q,[],[],[])
toc;

% same as last but with all handles
tic;
[Q,U,R,T] = model.getAvgHandles();
toc;

% value is now cached also for the other handles
tic;
[QN,UN,RN,TN] = solver.getAvg()
toc;
