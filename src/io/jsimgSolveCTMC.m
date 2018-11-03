function [QN,UN,RN,TN,QNc,UNc,RNc,TNc,CN,XN] = jmtSolveCTMC(fileName)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
model=JMT2LINE(fileName);
qn=model.getStruct;
for i=1:length(qn.visits)
    fprintf(['Visits chain ',num2str(i)]);
    qn.visits{i}
end
s=SolverCTMC(model);
[QN,UN,RN,TN]=s.getAvg();
[QNc,UNc,RNc,TNc]=s.getAvgChain();
[CN,XN]=s.getAvgSys();
end