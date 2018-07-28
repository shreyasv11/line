clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);
jobclass{1} = ClosedClass(model, 'Class1', 5, node{1}, 0);

node{1}.setService(jobclass{1}, Exp.fitMoments(1.0)); % mean = 1
node{2}.setService(jobclass{1}, Exp.fitMoments(2.0)); % mean = 2

model.addLink(node{1}, node{1}); 
model.addLink(node{1}, node{2});
model.addLink(node{2}, node{1}); 
model.addLink(node{2}, node{2});

node{1}.setProbRouting(jobclass{1}, node{1}, 0.7)
node{1}.setProbRouting(jobclass{1}, node{2}, 0.3)
node{2}.setProbRouting(jobclass{1}, node{1}, 1.0)

solver = {};
solver{end+1} = SolverCTMC(model);
solver{end+1} = SolverJMT(model);
solver{end+1} = SolverSSA(model);
solver{end+1} = SolverFluid(model);
solver{end+1} = SolverAMVA(model);
solver{end+1} = SolverNC(model);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());    
    AvgTable = solver{s}.getAvgTable()
end
