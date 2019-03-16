model = Network('RL');
queue = Queue(model, 'Queue', SchedStrategy.FCFS);

K = 3; N = [1,0,0];
for k=1:K
    jobclass{k} = ClosedClass(model, ['Class',int2str(k)], N(k), queue);
    queue.setService(jobclass{k}, Erlang.fitMeanAndOrder(k,2));
end

P = cellzeros(3,3,1,1); % 3x3 cell array (3 classes) of 1x1 matrices (1 node)
P{jobclass{1},jobclass{2}}(queue,queue) = 1.0;
P{jobclass{2},jobclass{3}}(queue,queue) = 1.0;
P{jobclass{3},jobclass{1}}(queue,queue) = 1.0;
model.link(P);

SolverCTMC(model).getAvgTable

SolverCTMC(model).getAvgSysTable

jobclass{1}.completes = false;
jobclass{2}.completes = false;
SolverCTMC(model).getAvgSysTable
