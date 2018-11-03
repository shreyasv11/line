clear;
model = Network('model');

scale = 1;
n = 5;
m = [1,2,1];
h=length(m);
S11 = 1e-4; 
S21 = 1;
S22 = 5;
S = [S11; S21; S22];

mainDelay = Delay(model, 'MainDelay');
cacheNode = Cache(model, 'Cache1', n, m, ReplacementPolicy.FIFO);
cacheDelay = Queue(model, 'CacheDelay', SchedStrategy.INF);
source = Source(model, 'Source');
sink = Sink(model, 'Sink');

jobClass = OpenClass(model, 'InitClass1', 0);
hitClass = OpenClass(model, 'HitClass1', 0);
missClass = OpenClass(model, 'MissClass1', 0);

RM1 = DiscreteDistrib((1/n)*ones(1,n)); % uniform reference 
cacheNode.setRead(jobClass, RM1);

mainDelay.setService(jobClass, Exp.fitMean(S11));
cacheDelay.setService(hitClass, Exp.fitMean(S21));
cacheDelay.setService(missClass, Exp.fitMean(S22));

cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

R = cellzeros(1,n,h,h); % access cost
for i=1:n
    pProm = 0.1;
    R{1,i} = diag(pProm*ones(1,h-2),2) + diag(pProm*ones(1,h-1),1) + diag((1-pProm)*ones(1,h));
    R{1,i} = dtmc_makestochastic(R{1,i});
%    R{1,i} = diag(ones(1,h-1),1);
    R{1,i}(end,end) = 1;
    R{1,i}
end
cacheNode.setAccessCosts(R)

P = cellzeros(3,3,5,5);
P{jobClass, jobClass}(source, mainDelay)=1;
P{jobClass, jobClass}(mainDelay, cacheNode)=1;
P{hitClass, hitClass}(cacheNode, cacheDelay)=1;
P{missClass, missClass}(cacheNode, cacheDelay)=1;
P{hitClass, jobClass}(cacheDelay, sink)=1;
P{missClass, jobClass}(cacheDelay, sink)=1;

model.link(P);

AvgTable = SolverSSA(model,'samples',1e4,'verbose',true,'method','serial').getAvgTable
