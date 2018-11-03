function task = getNodeTask(self,node)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
G = self.lqnGraph;
if ischar(node)
    taskid = findstring(G.Nodes.Name,node);
    task = G.Nodes.Task{taskid};
else
    task = G.Nodes.Task{node};
end
end
