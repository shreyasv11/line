model = Network('MRP');
% Block 1: nodes
delay = Delay(model,'WorkingState');
queue = Queue(model, 'RepairQueue', SchedStrategy.FCFS);
queue.setNumberOfServers(2);
% Block 2: classes
cclass = ClosedClass(model, 'Machines', 3, delay);
delay.setService(cclass, Exp(0.5));
queue.setService(cclass, Exp(4.0));
% Block 3: topology
model.link(Network.serialRouting(delay,queue));
% Block 4: solution
SolverCTMC(model,'keep',true).getAvgTable

global InfGen;
global StateSpace;
StateSpace
InfGen=full(InfGen)