model = Network('FRP');
% Block 1: nodes
delay = Delay(model,'WorkingState');
queue = Queue(model, 'RepairQueue', SchedStrategy.FCFS);
% Block 2: classes
cclass = ClosedClass(model, 'Machines', 2, delay);
delay.setService(cclass, Exp(1.0));
queue.setService(cclass, Exp(4.0));
% Block 3: topology
model.link(Network.serialRouting(delay,queue));
% Block 4: solution
SolverCTMC(model,'keep',true).getAvgTable

global InfGen;
global StateSpace;
StateSpace
InfGen=full(InfGen)