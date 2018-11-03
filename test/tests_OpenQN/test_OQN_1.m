

model = Network('model');

node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Sink(model, 'Sink');
node{4} = DelayStation(model, 'Delay');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = OpenClass(model, 'Class1', 0);
jobclass{2} = ClosedClass(model, 'Class2', 5, node{2}, 0);

model.addLink(node{1}, node{2});
model.addLink(node{2}, node{3});
model.addLink(node{2}, node{4});

myP = {};
myP{1} = [0,1,0,0; 
          0,0,1,0;
          0,0,0,0;
          0,0,0,0];
myP{2} = [0,0,0,0; 
          0,0,0,1;
          0,0,0,0;
          0,1,0,0];

node{1}.setArrival(jobclass{1}, Exp(1));

node{2}.setService(jobclass{1}, Erlang(4,2));
node{2}.setService(jobclass{2}, Exp(15));

node{4}.setService(jobclass{2}, Exp(100));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

model.link(myP);
