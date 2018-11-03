function [simNode, section] = saveGetStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

% the get strategy is always fcfs
queueGetStrategyNode = simNode.createElement('parameter');
queueGetStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.QueueGetStrategies.FCFSstrategy');
queueGetStrategyNode.setAttribute('name', 'FCFSstrategy');
section.appendChild(queueGetStrategyNode);
end