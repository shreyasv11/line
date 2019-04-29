function [submodels, levels] = getGraphLayers(self, lqnGraph, taskGraph)
% [SUBMODELS, LEVELS] = GETGRAPHLAYERS(LQNGRAPH, TASKGRAPH)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

submodels = layerize_loose(self,lqnGraph, taskGraph);
reftasks = [findstring(taskGraph.Nodes.Type,'R')];
levels = distances(taskGraph,reftasks(1),'Method','unweighted');
for r=2:length(reftasks)
    rlevel{r} = distances(taskGraph,reftasks(r),'Method','unweighted');
    rlevel{r}(isinf(rlevel{r})) = 0; % if a task is unreachable from a ref task, ignore the level obtained from this reftask
    levels = max(levels,rlevel{r});
end
levels = levels + 1;
levels(reftasks) = [];
[levels,order] = sort(levels);
submodels = {submodels{order}};
end

function submodels = layerize_loose(self,G, H)
% SUBMODELS = LAYERIZE_LOOSE(SELF,G, H)

initnodes = [findstring(G.Nodes.Type,'P')];
nextlevel = zeros(1,length(initnodes));
for r = 1:length(initnodes)
    nextlevel(1,r) = H.findnode(self.getNodeName(initnodes(r)));
end

% first build all layers
submodels = {};
for n=1:height(H.Nodes)
    pred = H.predecessors(n);
    if ~isempty(pred)
        submodels{end+1} = digraph();
        for p=pred'
            nameFrom = H.Nodes.Name{p};
            nameTo = H.Nodes.Name{n};
            submodels{end} = submodels{end}.addedge(nameFrom,nameTo);
        end
    end
end

% update full name
for l=1:length(submodels)
    submodels{l}.Nodes.Node = submodels{l}.Nodes.Name;
    for i=1:submodels{l}.numnodes
        idG=G.findnode(submodels{l}.Nodes.Name(i));
        submodels{l}.Nodes.Node(i) = G.Nodes.Node(idG);
    end
end
end
