clear;
model = CacheNetwork('model');

mainDelay = DelayStation(model, 'MainDelay');
cacheNode = CacheRouter(model, 'Cache', 3, [1], ReplacementPolicy.RAND);
hitDelay = DelayStation(model, 'HitDelay');
missDelay = DelayStation(model, 'MissDelay');

jobClass = ClosedClass(model, 'InitClass', 1, mainDelay, 0);
hitClass = ClosedClass(model, 'HitClass', 0, mainDelay, 0);
missClass = ClosedClass(model, 'MissClass', 0, mainDelay, 0);

mainDelay.setService(jobClass, Exp.fitMean(0.00001)); 
hitDelay.setService(hitClass, Exp.fitMean(1)); 
missDelay.setService(missClass, Exp.fitMean(1));

cacheNode.setRead(jobClass, Zipf(1.0));
cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

P = cellzeros(3,3,4,4);

P{jobClass.index, jobClass.index}(1,2)=1;      
P{hitClass.index, hitClass.index}(2,3)=1;
P{missClass.index, missClass.index}(2,4)=1;
P{hitClass.index, jobClass.index}(3,1)=1; 
P{missClass.index, jobClass.index}(4,1)=1;

model.linkNetwork(P);
SolverCTMC(model,'keep',false).getAvgTable
SolverSSA(model).getAvgTable
