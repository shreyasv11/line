function [simNode, section] = saveClassSwitchStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

paramNode = simNode.createElement('parameter');
paramNode.setAttribute('array', 'true');
paramNode.setAttribute('classPath', 'java.lang.Object');
paramNode.setAttribute('name', 'matrix');

numOfClasses = length(self.model.classes);
for i=1:numOfClasses
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    paramNode.appendChild(refClassNode);
    
    
    subParNodeRow = simNode.createElement('subParameter');
    subParNodeRow.setAttribute('array', 'true');
    subParNodeRow.setAttribute('classPath', 'java.lang.Float');
    subParNodeRow.setAttribute('name', 'row');
    for j=1:numOfClasses
        nextClass = self.model.classes{j,1};
        
        refClassNode = simNode.createElement('refClass');
        refClassNode.appendChild(simNode.createTextNode(nextClass.name));
        subParNodeRow.appendChild(refClassNode);
        
        subParNodeCell = simNode.createElement('subParameter');
        subParNodeCell.setAttribute('classPath', 'java.lang.Float');
        subParNodeCell.setAttribute('name', 'cell');
        valNode = simNode.createElement('value');
        valNode.appendChild(simNode.createTextNode(sprintf('%12.12f',currentNode.server.csFun(i,j))));
        subParNodeCell.appendChild(valNode);
        subParNodeRow.appendChild(subParNodeCell);
        
    end
    paramNode.appendChild(subParNodeRow);
    
end
section.appendChild(paramNode);

end
