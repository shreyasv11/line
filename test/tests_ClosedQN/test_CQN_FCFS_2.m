% Getting started example from the LINE documentation
model = Network('mrDemo3');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'QueueRepairman1', SchedStrategy.FCFS);
station{3} = Queue(model, 'QueueRepairman2', SchedStrategy.FCFS);
station{4} = Queue(model, 'QueueRepairman3', SchedStrategy.FCFS);

N1 = 2; jobclass{1} = ClosedClass(model, 'MachinesA', N1, station{1});
N2 = 2; jobclass{2} = ClosedClass(model, 'MachinesB', N2, station{1});

rate = [1,1; 2,0; 2,0; 0,10];
for i=1:4
    for r=1:2
        station{i}.setService(jobclass{r}, Exp(rate(i,r)));
    end
end

P{1} = zeros(4); P{1}(1,2:3)=[0.6, 0.4]; P{1}(2:4,1) = 1.0;
P{2} = zeros(4); P{2}(1,4)=[1.0]; P{2}(2:4,1) = 1.0;
model.link(P);

[Q,U,R,T] = model.getAvgHandles();

solver = SolverFluid(model,options);
[results,runtime] = solver.solve();
[QN,UN,RN,XN] = solver.getAvg();
UN(2,1)
UN(4,2)

solver = SolverMVA(model,options);
[results,runtime] = solver.solve();
[QN,UN,RN,XN] = solver.getAvg();
UN(2,1)
UN(4,2)

options.seed = 23000;
options.verbose = 0;
solver = SolverJMT(model,options);
;
[QNsim,UNsim,RNsim,XNsim] = solver.getAvg();
UNsim(2,1)
UNsim(4,2)
