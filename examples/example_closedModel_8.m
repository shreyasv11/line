% model with a self-looping class
if ~isoctave(), clearvars -except exampleName; end
model = Network('model');

delay = Delay(model, 'Delay');
queue = Queue(model, 'Queue1', SchedStrategy.FCFS);
jobclass{1} = ClosedClass(model, 'Class1', 10, delay, 0);
jobclass{2} = SelfLoopingClass(model, 'SLC', 1, queue, 0);

delay.setService(jobclass{1}, Exp.fitMean(1.0)); % mean = 1
queue.setService(jobclass{1}, Exp.fitMean(1.5)); % mean = 1.5
queue.setService(jobclass{2}, Exp.fitMean(1.5)); % mean = 1.5

P = model.initRoutingMatrix;
P{jobclass{1}} = [0.7,0.3;1.0,0];
% This may be alternatively specified as:
%P{1}(delay,[delay,queue]) = [0.7,0.3]; 
%P{1}(queue,[delay,queue]) = [1.0,0]; 
model.link(P);

solver = {};
solver{end+1} = SolverCTMC(model,'keep',true);
solver{end+1} = SolverJMT(model,'seed',23000,'verbose',true,'keep',true);
solver{end+1} = SolverSSA(model,'seed',23000,'verbose',true,'samples',5e3);
solver{end+1} = SolverFluid(model);
solver{end+1} = SolverMVA(model);
solver{end+1} = SolverNC(model,'exact');
solver{end+1} = SolverAuto(model);

AvgTable = cell(1,length(solver));
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());    
    AvgTable{s} = solver{s}.getAvgTable();
    AvgTable{s}
end
