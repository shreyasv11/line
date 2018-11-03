

model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Queue(model, 'Queue2', SchedStrategy.FCFS);
node{3}.setNumServers(3);
node{4} = Source(model, 'Source');
node{5} = Sink(model, 'Sink');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 1, node{1}, 0);
jobclass{3} = ClosedClass(model, 'Class3', 1, node{1}, 0);
jobclass{4} = OpenClass(model, 'Class4', 0);

node{4}.setArrival(jobclass{4}, Exp(0.5));

node{1}.setService(jobclass{1}, Exp(1));
node{1}.setService(jobclass{2}, Exp(1));
node{1}.setService(jobclass{3}, Exp(1));
node{1}.setService(jobclass{4}, Exp(1));

node{2}.setService(jobclass{1}, Exp(1));
node{2}.setService(jobclass{2}, Exp(1));
node{2}.setService(jobclass{3}, Exp(1));
node{2}.setService(jobclass{4}, Exp(1));

node{3}.setService(jobclass{1}, Exp(1));
node{3}.setService(jobclass{2}, Erlang(1,2));
node{3}.setService(jobclass{3}, Exp(1));
node{3}.setService(jobclass{4}, Exp(1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K);
for r=1:3 % closed classes
    myP{r} = [0,1,0,0,0; 0,0,1,0,0; 1,0,0,0,0; 0,0,0,1,0; 0,0,0,0,1];
end
myP{4} = [0,1,0,0,0; 0,0,1,0,0; 0,0,0,0,1; 1,0,0,0,0; 0,0,0,0,1];

model.link(myP);
