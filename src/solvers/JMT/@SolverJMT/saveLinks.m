function [simElem, simNode] = saveLinks(self, simElem, simNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
numOflinks = length(self.model.links);
for j=1:(numOflinks)
    currentConnection = self.model.links{j,1};
    connectionNode = simNode.createElement('connection');
    connectionNode.setAttribute('source', currentConnection{1}.name);
    connectionNode.setAttribute('target', currentConnection{2}.name);
    simElem.appendChild(connectionNode);
end
end
