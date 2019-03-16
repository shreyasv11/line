model = Network('model');
% Block 1: nodes
model = Network('model');
% Block 1: nodes
clientDelay = Delay(model, 'Client');
cacheNode = Cache(model, 'Cache', 1000, 50, ReplacementPolicy.LRU);
cacheDelay = Delay(model, 'CacheDelay');
% Block 2: classes
clientClass = ClosedClass(model, 'ClientClass', 1, clientDelay, 0);
hitClass = ClosedClass(model, 'HitClass', 0, clientDelay, 0);
missClass = ClosedClass(model, 'MissClass', 0, clientDelay, 0);

clientDelay.setService(clientClass, Immediate());
cacheDelay.setService(hitClass, Exp.fitMean(0.2));
cacheDelay.setService(missClass, Exp.fitMean(1));

cacheNode.setRead(clientClass, Zipf(1.4,1000));
cacheNode.setHitClass(clientClass, hitClass);
cacheNode.setMissClass(clientClass, missClass);

% Block 3: topology
P = cellzeros(3,3,4,4); % 3x3 cell, each with 4x4 zero matrices
% routing from client to cache
P{clientClass, clientClass}(clientDelay, cacheNode)=1;
% routing out of the cache
P{hitClass, hitClass}(cacheNode, cacheDelay)=1;
P{missClass, missClass}(cacheNode, cacheDelay)=1;
% return to the client
P{hitClass, clientClass}(cacheDelay, clientDelay)=1;
P{missClass, clientClass}(cacheDelay, clientDelay)=1;
% routing from cacheNode
model.linkNetwork(P);

% Block 4: solution
AvgTable = SolverSSA(model,'samples',2e4,'seed',1,'verbose',true).getAvgTable
AvgTable = SolverSSA(model,'samples',2e4,'seed',1,'verbose',true,'method','parallel').getAvgTable
AvgTable = SolverSSA(model,'samples',2e4,'seed',1,'verbose',true,'method','parallel').getAvgTable
