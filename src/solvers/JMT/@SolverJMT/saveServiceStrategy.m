function [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
strategyNode.setAttribute('name', 'ServiceStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    refClassNode2 = simDoc.createElement('refClass');
    refClassNode2.appendChild(simDoc.createTextNode(currentClass.name));
    strategyNode.appendChild(refClassNode2);
    
    if isempty(currentNode.server.serviceProcess{i})
        currentNode.server.serviceProcess{i} = {[],ServiceStrategy.LI,Disabled()};
    end
    distributionObj = currentNode.server.serviceProcess{i}{3};
    
    serviceTimeStrategyNode = simDoc.createElement('subParameter');
    
    if distributionObj.isDisabled()
        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.DisabledServiceTimeStrategy');
        serviceTimeStrategyNode.setAttribute('name', 'DisabledServiceTimeStrategy');
    elseif distributionObj.isImmediate()
        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ZeroServiceTimeStrategy');
        serviceTimeStrategyNode.setAttribute('name', 'ZeroServiceTimeStrategy');
    else
        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
        
        distributionNode = simDoc.createElement('subParameter');
        distributionNode.setAttribute('classPath', distributionObj.javaClass);
        switch distributionObj.name
            case 'Replayer'
                distributionNode.setAttribute('name', 'Replayer');
            otherwise
                distributionNode.setAttribute('name', distributionObj.name);
        end
        serviceTimeStrategyNode.appendChild(distributionNode);
        
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', distributionObj.javaParClass);
        distrParNode.setAttribute('name', 'distrPar');
        
        for k=1:distributionObj.getNumParams()
            subParNode = simDoc.createElement('subParameter');
            subParNode.setAttribute('classPath', distributionObj.getParam(k).paramClass);
            subParNode.setAttribute('name', distributionObj.getParam(k).paramName);
            subParValue = simDoc.createElement('value');
            switch distributionObj.getParam(k).paramClass
                case 'java.lang.Double'
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',distributionObj.getParam(k).paramValue)));
                case 'java.lang.Long'
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                case 'java.lang.String'
                    subParValue.appendChild(simDoc.createTextNode(distributionObj.getParam(k).paramValue));
            end
            subParNode.appendChild(subParValue);
            distrParNode.appendChild(subParNode);
        end
        
        serviceTimeStrategyNode.appendChild(distrParNode);
    end
    strategyNode.appendChild(serviceTimeStrategyNode);
    section.appendChild(strategyNode);
end
end
