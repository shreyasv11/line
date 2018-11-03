function [QN,UN,RN,TN,QNc,UNc,RNc,TNc,CN,XN] = jsimgSolveJMT(fileName)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
model=JMT2LINE(fileName);
qn=model.getStruct;
for i=1:length(qn.visits)
    fprintf(['Visits chain ',num2str(i)]);
    qn.visits{i}
end
options.verbose=1;
options.samples=2e4;
s=SolverJMT(model,options);
[QN,UN,RN,TN]=s.getAvg();
[QNc,UNc,RNc,TNc]=s.getAvgChain();
[CN,XN]=s.getAvgSys();
end