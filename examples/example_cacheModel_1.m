clear;
model = CacheNetwork('model');

node{1} = DelayStation(model, 'Delay');
node{2} = CacheNode(model, 'Cache1', 4, [1,2], ReplacementPolicy.RR);

jobclass{1} = ClosedClass(model, 'Class1', 1, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 1, node{1}, 0);

node{1}.setService(jobclass{1}, Exp.fitMean(10)); % mean = 1
node{1}.setService(jobclass{2}, Exp.fitMean(7)); % mean = 1

node{2}.setItemPopularity(jobclass{1}, Zipf(0.5));
node{2}.setItemPopularity(jobclass{2}, Zipf(0.7));

node{2}.setMissTime(Exp.fitMean(1)); % 
node{2}.setHitTime(Exp.fitMean(10), 1); % cache level 1
node{2}.setHitTime(Exp.fitMean(100), 2); % cache level 2

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
