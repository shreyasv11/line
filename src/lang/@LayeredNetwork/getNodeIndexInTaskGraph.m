function idx = getNodeIndexInTaskGraph(self,node)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
G = self.taskGraph;
idx = findstring(G.Nodes.Name,node);
%idx = H.findnode(node);
end