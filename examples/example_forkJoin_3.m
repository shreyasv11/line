model = Network('model');

source = Source(model,'Source');
queue1 = Queue(model,'Queue1',SchedStrategy.PS);
queue2 = Queue(model,'Queue2',SchedStrategy.PS);
fork1 = Fork(model,'Fork1');
fork1.setTasksPerLink(1);
fork2 = Fork(model,'Fork2');
fork2.setTasksPerLink(2);
join1 = Join(model,'Join1');
join2 = Join(model,'Join2');
sink = Sink(model,'Sink');

jobclass1 = OpenClass(model, 'class1');
jobclass2 = OpenClass(model, 'class2');

source.setArrival(jobclass1, Exp(0.25));
queue1.setService(jobclass1, Exp(1.0));
queue2.setService(jobclass1, Exp(0.75));

source.setArrival(jobclass2, Exp(0.25));
queue1.setService(jobclass2, Exp(2.0));
queue2.setService(jobclass2, Exp(2.0));

M = model.getNumberOfNodes;
R = model.getNumberOfClasses;
P = cellzeros(R,R,M,M);
P{jobclass1,jobclass1}(source,fork1) = 1;
P{jobclass1,jobclass1}(fork1,queue1) = 1.0;
P{jobclass1,jobclass1}(fork1,queue2) = 1.0;
P{jobclass1,jobclass1}(queue1,join1) = 1.0;
P{jobclass1,jobclass1}(queue2,join1) = 1.0;
P{jobclass1,jobclass1}(join1,sink) = 1.0;

P{jobclass2,jobclass2}(source,fork2) = 1;
P{jobclass2,jobclass2}(fork2,queue1) = 1.0;
P{jobclass2,jobclass2}(fork2,queue2) = 1.0;
P{jobclass2,jobclass2}(queue1,join2) = 1.0;
P{jobclass2,jobclass2}(queue2,join2) = 1.0;
P{jobclass2,jobclass2}(join2,sink) = 1.0;

model.link(P);
SolverJMT(model,'keep',true).getNodeAvgTable