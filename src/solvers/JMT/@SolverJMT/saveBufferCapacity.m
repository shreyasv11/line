function [simNode, section] = saveBufferCapacity(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

sizeNode = simNode.createElement('parameter');
sizeNode.setAttribute('classPath', 'java.lang.Integer');
sizeNode.setAttribute('name', 'size');
valueNode = simNode.createElement('value');
if isinf(currentNode.cap)
    valueNode.appendChild(simNode.createTextNode(int2str(-1)));
else
    valueNode.appendChild(simNode.createTextNode(int2str(currentNode.cap)));
end

sizeNode.appendChild(valueNode);
section.appendChild(sizeNode);
end
