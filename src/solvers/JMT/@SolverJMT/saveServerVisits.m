function [simNode, section] = saveServerVisits(self, simNode, section)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
visitsNode = simNode.createElement('parameter');
visitsNode.setAttribute('array', 'true');
visitsNode.setAttribute('classPath', 'java.lang.Integer');
visitsNode.setAttribute('name', 'numberOfVisits');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    visitsNode.appendChild(refClassNode);
    
    subParameterNode = simNode.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.Integer');
    subParameterNode.setAttribute('name', 'numberOfVisits');
    
    valueNode2 = simNode.createElement('value');
    valueNode2.appendChild(simNode.createTextNode(int2str(1)));
    
    subParameterNode.appendChild(valueNode2);
    visitsNode.appendChild(subParameterNode);
    section.appendChild(visitsNode);
end
end
