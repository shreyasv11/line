model = Network('mrDemo2');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'Queue', SchedStrategy.FCFS);

model.addLink(station{1}, station{2});
model.addLink(station{2}, station{1});

N1 = 10; jobclass{1} = ClosedClass(model, 'MachinesA', N1, station{1});
N2 = 2; jobclass{2} = ClosedClass(model, 'MachinesB', N2, station{1});

lambdaA = 10;    
muA = 3;       
lambdaB = 1;    
muB = 6;      

station{1}.setService(jobclass{1}, Exp(lambdaA));
station{2}.setService(jobclass{1}, Exp(muA));
station{1}.setService(jobclass{2}, Exp(lambdaB));
station{2}.setService(jobclass{2}, Exp(muB));

[Q,U,R,T] = model.getAvgHandles();
station{2}.setNumServers(2);

options = struct();
options.verbose = 0;
solver = SolverFluid(model,options);
[QN,UN,RN,XN] = solver.getAvg()

options = struct();
solver = SolverMVA(model,options);
[QNa,UNa,RNa,XNa] = solver.getAvg()
XNa(:)

options.seed = 23000;
solver = SolverJMT(model,options);
[QNsim,UNsim,RNsim,XNsim] = solver.getAvg()
XNsim(:)

