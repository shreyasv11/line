

model = Network('model');

node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
node{3} = Sink(model, 'Sink');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = OpenClass(model, 'Class1', 0);

model.addLink(node{1}, node{2});
model.addLink(node{2}, node{3});

myP = cell(1,1);
myP{1} = [0,1,0; 
          0,0,1;
          0,0,0];

node{1}.setArrival(jobclass{1}, Exp(1));
node{2}.setService(jobclass{1}, Erlang(4,2));

model.link(myP);

[Q,U,R,T] = model.getAvgHandles();
options.keep = false;
options.verbose = 1;
options.cutoff = 12;
options.seed = randi(100,1,1);
options.samples = 1e4;
optionsjmt = options; optionsjmt.samples = 1e5;
solver = cell(1,1);
% This part illustrates the execution of different solvers
solver{1} = SolverJMT(model,optionsjmt);
solver{2} = SolverMAM(model,options);
for s=1:length(solver)
    if ~isempty(solver{s})
        [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
        [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
        [CN{s},XN{s}] = solver{s}.getAvgSys();
    end
end

