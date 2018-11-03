function [lqnGraph,taskGraph]=getGraph(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

if isempty(self.lqnGraph)
    self.generateGraph;
end
lqnGraph = self.lqnGraph;
taskGraph = self.taskGraph;
end
