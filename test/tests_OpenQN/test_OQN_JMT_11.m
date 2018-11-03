%% oqn-11
disp('wrong, this model has CS between open and closed and both closed empty at start')
model = JMT2LINE('oqn-11.jsimg'); 
options=struct; 
options.samples = 1e4;
[Q,U,R,T] = model.getAvgHandles(); 

ssim=SolverJMT(model,options); 
 
[QNsim,UNsim,RNsim,XNsim] = ssim.getAvg();

samva=SolverMVA(model,options); 
 
[QN,UN,RN,TN] = samva.getAvg();

QNsim
QN
