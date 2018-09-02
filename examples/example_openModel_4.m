clear;
model = Network('model');

source = Source(model,'Source');
queue = QueueingStation(model, 'Queue', SchedStrategy.FCFS);
sink = Sink(model,'Sink');

jobclass = OpenClass(model, 'OpenClass', 0);

source.setArrival(jobclass, Exp(1));
cwd = fileparts(mfilename('fullpath'));
queue.setService(jobclass, Replayer([cwd,filesep,'example_openModel_4_trace.txt']));


model.link([0,1,0;,0,0,1;0,0,0]);

AvgTable = SolverJMT(model).getAvgTable
