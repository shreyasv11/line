
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Queue(model, 'Queue2', SchedStrategy.PS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 2, node{1}, 0);

model.addLink(node{1}, node{1});
model.addLink(node{1}, node{2});
model.addLink(node{1}, node{3});
model.addLink(node{2}, node{1});
model.addLink(node{3}, node{1});

node{1}.setService(jobclass{1}, Exp(3));
node{1}.setService(jobclass{2}, Exp(0.5));

node{2}.setService(jobclass{1}, Exp(0.1));
node{2}.setService(jobclass{2}, Exp(1));

node{3}.setService(jobclass{1}, Exp(0.1));
node{3}.setService(jobclass{2}, Exp(2));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K,K);
myP{1,1} = [0.3,0.1,0;
    0.2,0,0
    1,0,0];
myP{1,2} = [0.5,0,0.1;
    0.8,0,0
    0,0,0];
%myP{1,1}+myP{1,2}
myP{2,2} = [0,0.5,0.5;
    0,0,0
    0,0,0];
myP{2,1} = [0,0,0;
    1,0,0
    0,1,0];
%myP{2,1}+myP{2,2}

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
