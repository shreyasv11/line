function [entry, entryFullName] = findEntryOfActivity(self,activity)
% [ENTRY, ENTRYFULLNAME] = FINDENTRYOFACTIVITY(SELF,ACTIVITY)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

G = self.lqnGraph;
entry = '';
actIdx = self.getNodeIndex(activity);
try
    actobj = self.getNodeObject(actIdx);
catch
    actobj = self.getNodeObject(actIdx);
end
% if a task activity, then we need to search on the graph
%if isempty(actobj.parentName)
preids = G.predecessors(actIdx);
for preIdx = preids(:)'
    if G.Edges.Type(self.findEdgeIndex(preIdx,actIdx)) == 0 % not a call
        if strcmpi(G.Nodes.Type{preIdx},'E')
            entry = G.Nodes.Name{preIdx};
            entryFullName = G.Nodes.Node{preIdx};
            return
        else % if it is an activity, go recursively
            [entry, entryFullName] = self.findEntryOfActivity(G.Nodes.Name{preIdx});
            return
        end
    end
end
%else
%    entry = actobj.parentName;
%end
end
