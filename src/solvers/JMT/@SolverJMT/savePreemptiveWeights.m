function [simNode, section] = savePreemptiveWeights(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
visitsNode = simNode.createElement('parameter');
visitsNode.setAttribute('array', 'true');
visitsNode.setAttribute('classPath', 'java.lang.Double');
visitsNode.setAttribute('name', 'serviceWeights');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    visitsNode.appendChild(refClassNode);
    
    subParameterNode = simNode.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.Double');
    subParameterNode.setAttribute('name', 'serviceWeight');
    
    valueNode2 = simNode.createElement('value');
    if isempty(currentNode.schedStrategyPar) % PS case
        valueNode2.appendChild(simNode.createTextNode(int2str(1)));
    else
        valueNode2.appendChild(simNode.createTextNode(num2str(currentNode.schedStrategyPar(i))));
    end
    
    subParameterNode.appendChild(valueNode2);
    visitsNode.appendChild(subParameterNode);
    section.appendChild(visitsNode);
end
end
