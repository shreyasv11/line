function [simNode, section] = savePreemptiveStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
visitsNode = simNode.createElement('parameter');
visitsNode.setAttribute('array', 'true');
visitsNode.setAttribute('classPath', 'jmt.engine.NetStrategies.PSStrategy');
visitsNode.setAttribute('name', 'PSStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    visitsNode.appendChild(refClassNode);
    
    subParameterNode = simNode.createElement('subParameter');
    switch currentNode.schedStrategy
        case SchedStrategy.PS
            subParameterNode.setAttribute('classPath', 'jmt.engine.NetStrategies.PSStrategies.EPSStrategy');
            subParameterNode.setAttribute('name', 'EPSStrategy');
        case SchedStrategy.DPS
            subParameterNode.setAttribute('classPath', 'jmt.engine.NetStrategies.PSStrategies.DPSStrategy');
            subParameterNode.setAttribute('name', 'DPSStrategy');
        case SchedStrategy.GPS
            subParameterNode.setAttribute('classPath', 'jmt.engine.NetStrategies.PSStrategies.GPSStrategy');
            subParameterNode.setAttribute('name', 'GPSStrategy');
    end
    
    visitsNode.appendChild(subParameterNode);
    section.appendChild(visitsNode);
end
end

