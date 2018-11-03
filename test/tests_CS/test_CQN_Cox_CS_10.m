% Schwetman
model = Network('model');

node{1} = Queue(model, 'CPU1', SchedStrategy.PS);
node{2} = Queue(model, 'IO2', SchedStrategy.PS);
node{3} = Queue(model, 'IO3', SchedStrategy.FCFS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 3, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 0, node{1}, 0);

model.addLink(node{1}, node{1});
model.addLink(node{1}, node{2});
model.addLink(node{1}, node{3});
model.addLink(node{2}, node{1});
model.addLink(node{3}, node{1});

node{1}.setService(jobclass{1}, Exp(100));
node{1}.setService(jobclass{2}, Exp(20));

node{2}.setService(jobclass{1}, Exp(14.29));
node{2}.setService(jobclass{2}, Exp(14.29));

node{3}.setService(jobclass{1}, Exp(10));
node{3}.setService(jobclass{2}, Exp(10));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K,K);

myP{1,1} = [
    0.0, 0.7, 0.2
    1.0,0.0,0.0;
    1.0,0.0,0.0
    ];

myP{1,2} = [
    0.1,0.0,0.0
    0.0,0.0,0.0
    0.0,0.0,0.0
    ];

myP{2,1} = [
    0.2,0.0,0.0
    0.0,0.0,0.0
    0.0,0.0,0.0
    ];

myP{2,2} = [
    0.0,0.3,0.5;
    1.0,0.0,0.0;
    1.0,0.0,0.0
    ];

% This illustrates the generation of the class-switches from a matrix spec
for i=1:M
    for j=1:M
        for r=1:K
            for s=1:K
                P((i-1)*K+r,(j-1)*K+s) = myP{r,s}(i,j);
            end
        end
    end
end

model.link(myP);
