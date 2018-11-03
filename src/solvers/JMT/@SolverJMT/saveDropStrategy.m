function [simNode, section] = saveDropStrategy(self, simNode, section)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

schedStrategyNode = simNode.createElement('parameter');
schedStrategyNode.setAttribute('array', 'true');
schedStrategyNode.setAttribute('classPath', 'java.lang.String');
schedStrategyNode.setAttribute('name', 'dropStrategies');
numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    schedStrategyNode.appendChild(refClassNode);
    
    subParameterNode = simNode.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.String');
    subParameterNode.setAttribute('name', 'dropStrategy');
    
    valueNode2 = simNode.createElement('value');
    valueNode2.appendChild(simNode.createTextNode('drop'));
    
    subParameterNode.appendChild(valueNode2);
    schedStrategyNode.appendChild(subParameterNode);
    section.appendChild(schedStrategyNode);
end
end
