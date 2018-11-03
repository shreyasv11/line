model=JMT2LINE('C:\Users\csg\OneDrive - Imperial College London\code\jmt.local\tests\old\NOTgoodRANDOM_FCFS_New.jsimg');
[Q,U,R,T]=model.getAvgHandles;
options.verbose=0;
s=SolverSSA(model,options);
[QN,UN,RN,TN]=s.getAvg()
s=SolverJMT(model,options);
[QN,UN,RN,TN]=s.getAvg()
