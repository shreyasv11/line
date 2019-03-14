function idx = getNodeIndex(self,node)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

%G = self.lqnGraph;
%idx = findstring(G.Nodes.Name,node);
%idx = G.findnode(node);
idx = findstring(self.nodeNames,node);
end