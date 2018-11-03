

model = Network('model');

node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Sink(model, 'Sink');

jobclass{1} = OpenClass(model, 'Class1', 0);
jobclass{2} = OpenClass(model, 'Class2', 0);

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K,K);
myP{1,1} = [
    0,1,0;
    0,0,0.5;
    0,0,0
    ];
myP{1,2} = [
    0,0,0;
    0,0,0.5;
    0,0,0
    ];
myP{2,1} = [
    0,0,0;
    0,0,0;
    0,0,0
    ];
myP{2,2} = [
    0,1,0;
    0,0,1;
    0,0,0
    ];

node{1}.setArrival(jobclass{1}, Exp(0.5));
node{1}.setArrival(jobclass{2}, Exp(0.3));

node{2}.setService(jobclass{1}, Erlang(4,2));
node{2}.setService(jobclass{2}, Exp(15));

model.link(myP);
