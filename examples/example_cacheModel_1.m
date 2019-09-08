if ~isoctave(), clearvars -except exampleName; end

model = Network('model');

n = 3; % number of items
m = 2; % cache capacity 

source = Source(model, 'Source');
cacheNode = Cache(model, 'Cache', n, m, ReplacementStrategy.FIFO);
sink = Sink(model, 'Sink');

jobClass = OpenClass(model, 'InitClass', 0);
hitClass = OpenClass(model, 'HitClass', 0);
missClass = OpenClass(model, 'MissClass', 0);

source.setArrival(jobClass, Exp(1));

pAccess = DiscreteSampler((1/n)*ones(1,n));  % uniform item references
cacheNode.setRead(jobClass, pAccess);

cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

P = model.initRoutingMatrix;

P{jobClass, jobClass}(source, cacheNode) =  1.0;
P{hitClass, hitClass}(cacheNode, sink) =  1.0;
P{missClass, missClass}(cacheNode, sink) =  1.0;

model.link(P);

solver{1} = SolverCTMC(model,'keep',false,'cutoff',1,'seed',1);
AvgTable{1} = solver{1}.getAvgNodeTable

solver{2} = SolverSSA(model,'samples',1e4,'verbose',true,'method','serial','seed',1);
AvgTable{2} = solver{2}.getAvgNodeTable
