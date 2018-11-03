
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 1, node{2}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 0, node{2}, 0);

model.addLink(node{1}, node{1});
model.addLink(node{1}, node{2});
model.addLink(node{2}, node{1});

node{1}.setService(jobclass{1}, Exp(1));
node{1}.setService(jobclass{2}, Exp(1));

node{2}.setService(jobclass{1}, Exp(1));
node{2}.setService(jobclass{2}, Exp(1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K,K);
myP{1,1} = [0,0.5; 
            1,0];
myP{1,2} = [0,0.5; 
            0,0];
myP{2,2} = [0,0; 
            1,0];
myP{2,1} = [0,1; 
            0,0];
                
%pause
model.link(myP);
