model = Network('M/M/1');
source = Source(model, 'mySource');
queue = QueueingStation(model, 'myQueue', SchedStrategy.FCFS); 
sink = Sink(model, 'mySink');
oclass = OpenClass(model, 'myClass');
source.setArrival(oclass, Exp(1));
queue.setService(oclass, Exp(2));
model.link(Network.serialRouting(source,queue,sink));
SolverJMT(model).getAvgTable
