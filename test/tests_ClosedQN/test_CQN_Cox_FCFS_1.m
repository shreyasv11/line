% Getting started example from the LINE documentation

model = Network('mrDemo3');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'QueueRepairman1', SchedStrategy.FCFS);
station{3} = Queue(model, 'QueueRepairman2', SchedStrategy.FCFS);
station{4} = Queue(model, 'QueueRepairman3', SchedStrategy.FCFS);

N1 = 10; jobclass{1} = ClosedClass(model, 'MachinesA', N1, station{1});
N2 = 10; jobclass{2} = ClosedClass(model, 'MachinesB', N2, station{1});

rate = [1,1; 2,1e6; 2,1e6; 2,3];
for i=1:4
    for r=1:2
        if rate(i,r)>0
            station{i}.setService(jobclass{r}, HyperExp.fitMeanAndSCV(1/rate(i,r),100));
        end
    end
end

P{1} = zeros(4); P{1}(1,2:4)=[1/3, 1/3, 1/3]; P{1}(2:4,1) = 1.0;
P{2} = zeros(4); P{2}(1,4)=[1.0]; P{2}(2:4,1) = 1.0;
model.link(P);

[Q,U,R,T] = model.getAvgHandles();

options.keep = true;
options.verbose = 0;
options.seed = 23000;
% This part illustrates the execution of different solvers
solver{1} = SolverCTMC(model,options);
solver{2} = SolverJMT(model,options);
solver{3} = SolverSSA(model,options);
solver{4} = SolverFluid(model,options);
solver{5} = SolverMVA(model,options);
for s=1:length(solver)
    if ~isempty(solver{s})
    [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
    [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
    [CN{s},XN{s}] = solver{s}.getAvgSys();
    end
end
RNsim