clear;
model = Network('model');

node{1} = Delay(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Source(model,'Source');
node{4} = Sink(model,'Sink');

jobclass{1} = ClosedClass(model, 'Class1', 2, node{1}, 0);
jobclass{2} = OpenClass(model, 'Class2', 0);
jobclass{3} = ClosedClass(model, 'Class3', 1, node{1}, 0);

node{1}.setService(jobclass{1}, Erlang(3,2));
node{1}.setService(jobclass{2}, HyperExp(0.5,3.0,10.0));
node{1}.setService(jobclass{3}, Exp(1));

node{2}.setService(jobclass{1}, HyperExp(0.1,1.0,10.0));
node{2}.setService(jobclass{2}, Exp(1));
node{2}.setService(jobclass{3}, Exp(1));

node{3}.setArrival(jobclass{2}, Exp(0.1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = cell(K,K);
P{1,1} = zeros(4); P{1,1}(1:2,1:2) = circul(2);
P{1,2} = zeros(4);
P{1,3} = zeros(4);
P{2,1} = zeros(4);
P{2,2} = [0,1,0,0; 0,0,0,1; 1,0,0,0; 0,0,0,0];
P{2,3} = zeros(4);
P{3,1} = zeros(4);
P{3,2} = zeros(4);
P{3,3} = zeros(4); P{3,3}(1:2,1:2) = circul(2);

model.link(P);
%%
solver = {};
solver{end+1} = SolverJMT(model,'method','jsim','seed',23001,'samples',1e6);
solver{end+1} = SolverMVA(model,'method','default');
%solver{end+1} = SolverNC(model,'method','exact');
solver{end+1} = SolverJMT(model,'method','jmva','verbose',true,'keep',true);
solver{end+1} = SolverJMT(model,'method','jmva.comom','verbose',true,'keep',true);
solver{end+1} = SolverJMT(model,'method','jmva.recal','verbose',true);
solver{end+1} = SolverJMT(model,'method','jmva.ls','samples',1e4,'verbose',true,'keep',true);

AvgTable = {};
logNC = [];
for s=1:length(solver)
    try
        fprintf(1,'SOLVER: %s METHOD: %s\n',solver{s}.getName(),solver{s}.getOptions.method);
        solver{s}.getAvgTable
    catch me
        me
    end
end
