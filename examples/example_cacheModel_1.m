% basic example
clear;
model = CacheNetwork('model');
n = 5;
node{1} = DelayStation(model, 'Delay');
node{2} = CacheRouter(model, 'Cache1', n, [2,1], ReplacementPolicy.RAND);

jobclass{1} = ClosedClass(model, 'Class1', 1, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 0, node{1}, 0);

node{1}.setService(jobclass{1}, Exp.fitMean(1)); % mean = 1
node{1}.setService(jobclass{2}, Exp.fitMean(7)); % mean = 1

node{2}.setReference(jobclass{1}, Zipf(0.5,n));
node{2}.setReference(jobclass{2}, Zipf(0.7,n));

% node{2}.setMissTime(Exp.fitMean(1)); %
% node{2}.setHitTime(Exp.fitMean(10), 1); % cache level 1
% node{2}.setHitTime(Exp.fitMean(100), 2); % cache level 2

%P = cell(2);
% P{1,1} = [0.0,0.4; 
%           0.2,0];
% P{1,2} = [0.6,0; 
%           0.8,0];
% P{2,2} = [0,1; 
%           0,0];
% P{2,1} = [0,0; 
%           1,0];
P{1} = circul(2);
P{2} = circul(2);

model.linkNetwork(P);

%SolverCTMC(model,'keep',false).getAvgTable
