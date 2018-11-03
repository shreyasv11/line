%% oqn-10
fprintf(1,'wrong this model has a droprule')

model = JMT2LINE('oqn-10.jsimg'); 
options=struct; 
options.samples = 1e4;
[Q,U,R,T] = model.getAvgHandles(); 

ssim=SolverJMT(model,options); 
 
[QNsim,UNsim,RNsim,XNsim] = ssim.getAvg();

samva=SolverMVA(model,options); 
 
[QN,UN,RN,TN] = samva.getAvg();

QNsim
QN
