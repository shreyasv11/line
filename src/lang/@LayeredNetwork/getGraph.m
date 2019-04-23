function [lqnGraph,taskGraph]=getGraph(self)
% [LQNGRAPH,TASKGRAPH]=GETGRAPH(SELF)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

if isempty(self.lqnGraph)
    self.generateGraph;
end
lqnGraph = self.lqnGraph;
taskGraph = self.taskGraph;
end

