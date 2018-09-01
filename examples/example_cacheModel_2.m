%clear;
model = CacheNetwork('model');

alpha = 1.0;
N=1;
n=3;
m=[2];
mainDelay = DelayStation(model, 'MainDelay');
cacheNode = CacheRouter(model, 'Cache', n, m, ReplacementPolicy.RAND);
hitNode = QueueingStation(model, 'HitNode', SchedStrategy.INF);
missNode = QueueingStation(model, 'MissNode', SchedStrategy.INF);

jobClass = ClosedClass(model, 'InitClass', N, mainDelay, 0);
hitClass = ClosedClass(model, 'HitClass', 0, mainDelay, 0);
missClass = ClosedClass(model, 'MissClass', 0, mainDelay, 0);

mainDelay.setService(jobClass, Exp.fitMean(1)); 
hitNode.setService(hitClass, Exp.fitMean(1)); 
missNode.setService(missClass, Exp.fitMean(2));

cacheNode.setReference(jobClass, Zipf(alpha,n));
cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

P = cellzeros(3,3,4,4);

P{jobClass.index, jobClass.index}(1,2)=1;      
P{hitClass.index, hitClass.index}(2,3)=1;
P{missClass.index, missClass.index}(2,4)=1;
P{hitClass.index, jobClass.index}(3,1)=1; 
P{missClass.index, jobClass.index}(4,1)=1;

model.linkNetwork(P);
AvgTable = SolverCTMC(model,'keep',true).getAvgTable
AvgTable = SolverSSA(model,'samples',1e3).getAvgTable

global keep_infgen;
global keep_statespace;
Q = keep_infgen;
pi = ctmc_solve(Q);
SS = keep_statespace;
s300 = findrows(SS(:,1:7),[3,0,0, 0,0,0,1,3]);
s200 = findrows(SS(:,1:7),[2,0,0, 0,0,0,1,3]);
s100 = findrows(SS(:,1:7),[1,0,0, 0,0,0,1,3]);
sum(pi(s300))/sum(pi(s200))
sum(pi(s200))/sum(pi(s100))

s300b = findrows(SS(:,1:7),[3,0,0, 0,0,0,2,3]);
s200b = findrows(SS(:,1:7),[2,0,0, 0,0,0,2,3]);
s100b = findrows(SS(:,1:7),[1,0,0, 0,0,0,2,3]);
sum(pi(s300b))/sum(pi(s200b))
sum(pi(s200b))/sum(pi(s100b))

sum(pi(s300))/sum(pi(s300b))
sum(pi(s200))/sum(pi(s200b))
sum(pi(s100))/sum(pi(s100b))

qn=model.getStruct;
global keep_eventfilt;
D1=zeros(size(keep_eventfilt{1})); for a=1:length(keep_eventfilt) if qn.sync{a}.active{1}.node==2 D1=D1+keep_eventfilt{a}; end, end
MAPdep={Q-D1,D1};
pie = map_pie(MAPdep);

sum(pie(s300))/sum(pie(s200))
sum(pie(s200))/sum(pie(s100))

sum(pie(s300b))/sum(pie(s200b))
sum(pie(s200b))/sum(pie(s100b))

sum(pie(s300))/sum(pie(s300b))
sum(pie(s200))/sum(pie(s200b))
sum(pie(s100))/sum(pie(s100b))