function acts=listActivitiesOfEntry(self,entry)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
G = self.lqnGraph;
acts = G.Nodes.Name(findstring(G.Nodes.Entry,entry));
acts = {acts{:}};
end

