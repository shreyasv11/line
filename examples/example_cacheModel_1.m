clear;
model = CacheNetwork('model');

node{1} = DelayStation(model, 'Delay');
node{2} = CacheStation(model, 'Cache1', [1,4], SchedStrategy.INF, ReplacementPolicy.RR); node{2}.setNumServers(4);

jobclass{1} = ClosedClass(model, 'Class1', 1, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 1, node{1}, 0);

node{1}.setService(jobclass{1}, Exp.fitMean(10)); % mean = 1
node{1}.setService(jobclass{2}, Exp.fitMean(7)); % mean = 1

itemtype{1} = ItemType(model, 'ItemType1', 3, node{2});
itemtype{2} = ItemType(model, 'ItemType2', 2, node{2});

node{2}.setService(jobclass{1}, Disabled());
node{2}.setService(jobclass{2}, Disabled());

node{2}.setPopularity(jobclass{1}, itemtype{1}, 0.5, Zipf(0.5));
node{2}.setPopularity(jobclass{1}, itemtype{2}, 0.5, Zipf(1.5));
node{2}.setPopularity(jobclass{2}, itemtype{1}, 1.0, Zipf(0.7));
node{2}.setPopularity(jobclass{2}, itemtype{2}, 0.0, Disabled());

node{2}.setMissTime(itemtype{1}, Exp(1)); % mean = 1/5
node{2}.setHitTime(itemtype{1}, Exp(10), 1); % mean = 1/30, cache level 1
node{2}.setHitTime(itemtype{1}, Exp(100), 2); % mean = 1/30, cache level 2

node{2}.setMissTime(itemtype{2}, Exp(2)); % mean = 1/5
node{2}.setHitTime(itemtype{2}, Exp(20), 1); % mean = 1/30, cache level 1
node{2}.setHitTime(itemtype{2}, Exp(200), 2); % mean = 1/30, cache level 2

P = cell(1,2);
P{1} = circul(length(node));
P{2} = circul(length(node));

model.linkNetwork(P);

% simoptions = Solver.defaultOptions; simoptions.seed = 23000; simoptions.verbose = true;
% solver = {};
% solver{end+1} = SolverCTMC(model);
% solver{end+1} = SolverJMT(model, simoptions);
% solver{end+1} = SolverSSA(model, simoptions);
% solver{end+1} = SolverFluid(model);
% solver{end+1} = SolverMVA(model);
% solver{end+1} = SolverNC(model);
% solver{end+1} = SolverAuto(model);
% 
% for s=1:length(solver)
%     fprintf(1,'SOLVER: %s\n',solver{s}.getName());    
%     AvgTable = solver{s}.getAvgTable()
% end
