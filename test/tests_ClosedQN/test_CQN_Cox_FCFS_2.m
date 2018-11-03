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

P{1,1} = zeros(4); P{1,1}(1,2:4) = [1/3, 1/3, 1/3]; 
P{1,2} = zeros(4); P{1,2}(2:4,1) = 1.0;
P{2,2} = zeros(4); P{2,2}(1,4) = [1.0]; 
P{2,1} = zeros(4); P{2,1}(2:4,1) = 1.0;
model.link(P);

[Q,U,R,T] = model.getAvgHandles();

options.verbose = 0;
solver = SolverFluid(model,options);
;
[QN,UN,RN,XN] = solver.getAvg();
QN
RN

solver = SolverMVA(model,options);
[results,runtime] = solver.solve();
[QN,UN,RN,XN] = solver.getAvg();
QN
RN

options.seed = randi(100000);
options.verbose = 0;
options.keep=true;
options.samples = 1e4;    
solver = SolverJMT(model,options);
;
[QNsim,UNsim,RNsim,XNsim] = solver.getAvg();
QNsim
RNsim