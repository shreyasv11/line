clear;
model = CacheNetwork('model');

scale = 1;
n = 10;
m = [2];
h=length(m);
N = [1];
S11 = 1e-4; 
S21 = 1;
S22 = 5;
S = [S11; S21; S22];

mainDelay = DelayStation(model, 'MainDelay');
cacheNode = CacheRouter(model, 'Cache1', n, m, ReplacementPolicy.RAND);
hitDelay = QueueingStation(model,'HitDelay',SchedStrategy.INF);

jobClass = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
hitClass = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
missClass = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);

RM1 = DiscreteDistrib((1/n)*ones(1,n));
%RM1 = Zipf(0.5,n);
cacheNode.setReference(jobClass, RM1);

mainDelay.setService(jobClass, Exp.fitMean(S11));
hitDelay.setService(hitClass, Exp.fitMean(S21));
hitDelay.setService(missClass, Exp.fitMean(S22));

cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

P = cellzeros(3,3,3,3);
P{jobClass, jobClass}(mainDelay, cacheNode)=1;
P{hitClass, hitClass}(cacheNode, hitDelay)=1;
P{missClass, missClass}(cacheNode, hitDelay)=1;
P{hitClass, jobClass}(hitDelay, mainDelay)=1;
P{missClass, jobClass}(hitDelay, mainDelay)=1;

model.linkNetwork(P);

AvgTable = SolverCTMC(model,'keep',true).getAvgTable
AvgTable = SolverSSA(model,'samples',1e4,'verbose',true).getAvgTable
