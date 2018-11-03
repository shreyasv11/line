

model = Network('model');

node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Sink(model, 'Sink');
node{4} = DelayStation(model, 'Delay');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = OpenClass(model, 'Class1', 0);
jobclass{2} = OpenClass(model, 'Class2', 0);
%jobclass{2} = ClosedClass(model, 'Class2', 5, node{2}, 0);

myP = cell(1,2);
myP{1} = [0,1,0,0; 
          0,0,1,0;
          0,0,0,0;
          0,0,0,0];
myP{2} = [0,1,0,0; 
          0,0,0,1;
          0,0,0,0;
          0,0.5,0.5,0];

node{1}.setArrival(jobclass{1}, HyperExp.fitMeanAndSCV(0.6,1.1));
node{1}.setArrival(jobclass{2}, HyperExp.fitMeanAndSCV(1,2.1));

node{2}.setService(jobclass{1}, Erlang(4,2));
node{2}.setService(jobclass{2}, Exp(15));

node{4}.setService(jobclass{2}, Exp(100));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

model.link(myP);
