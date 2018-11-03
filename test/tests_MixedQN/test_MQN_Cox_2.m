

model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
node{3} = Queue(model, 'Queue2', SchedStrategy.FCFS);
node{3}.setNumServers(3);
node{4} = Source(model, 'Source');
node{5} = Sink(model, 'Sink');

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 2, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 1, node{1}, 0);
jobclass{3} = ClosedClass(model, 'Class3', 1, node{1}, 0);
jobclass{4} = OpenClass(model, 'Class4', 0);

node{4}.setArrival(jobclass{4}, Exp(0.5));

node{1}.setService(jobclass{1}, Exp(1));
node{1}.setService(jobclass{2}, Exp(1));
node{1}.setService(jobclass{3}, Exp(1));
node{1}.setService(jobclass{4}, Exp(1));

node{2}.setService(jobclass{1}, Exp(1));
node{2}.setService(jobclass{2}, Exp(1));
node{2}.setService(jobclass{3}, Exp(1));
node{2}.setService(jobclass{4}, Exp(1));

node{3}.setService(jobclass{1}, Exp(1));
node{3}.setService(jobclass{2}, Erlang(1,2));
node{3}.setService(jobclass{3}, Exp(1));
node{3}.setService(jobclass{4}, Exp(1));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

myP = cell(K,1);
for r=1:3 % closed classes
    myP{r} = [0,1,0,0,0; 0,0,1,0,0; 1,0,0,0,0; 0,0,0,0,0; 0,0,0,0,0];
end
myP{4} = [0,1,0,0,0; 0,0,1,0,0; 0,0,0,0,1; 1,0,0,0,0; 0,0,0,0,0];

model.link(myP);
% if 1
%     [Q,U,R,X] = model.getAvgHandles();
%     options.keep=true;
%     options.verbose=1;
%     options.samples=1e4;
%     solver={};
%     solver{end+1} = SolverJMT(model,options);
%     for s=1:length(solver)
%         fprintf(1,'SOLVER: %s\n',solver{s}.getName());
%         [results,runtime] = solver{s}.solve(options);
%         [QN,UN,RN,XN] = solver{s}.getAvg()
%     end
% end