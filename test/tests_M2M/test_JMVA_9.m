clear;
D = [10,5; 5,9]; % S(i,r) - mean service time of class r at station i
A = [1,2]/20; % A(r) - arrival rate of class r
Z = [1,2;3,4]; % Z(r)  mean service time of class r at delay station i
model = Network.tandemPsInf(A,D,Z);
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
