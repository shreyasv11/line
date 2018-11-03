function [simNode, section] = saveNumberOfServers(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
sizeNode = simNode.createElement('parameter');
sizeNode.setAttribute('classPath', 'java.lang.Integer');
sizeNode.setAttribute('name', 'maxJobs');

valueNode = simNode.createElement('value');
valueNode.appendChild(simNode.createTextNode(int2str(currentNode.numberOfServers)));

sizeNode.appendChild(valueNode);
section.appendChild(sizeNode);
end
