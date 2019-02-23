function [simDoc, section] = saveArrivalStrategy(self, simDoc, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
strategyNode.setAttribute('name', 'ServiceStrategy');

numOfClasses = length(self.model.classes);
for i=1:numOfClasses
    currentClass = self.model.classes{i,1};
    switch currentClass.type
        case 'closed'
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simDoc.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            subParValue = simDoc.createElement('value');
            subParValue.appendChild(simDoc.createTextNode('null'));
            serviceTimeStrategyNode.appendChild(subParValue);
            strategyNode.appendChild(serviceTimeStrategyNode);
            section.appendChild(strategyNode);
            
        case 'open'
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simDoc.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            
            distributionObj = currentNode.input.sourceClasses{i}{3};
            if isempty(distributionObj.javaParClass) % Disabled distribution
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode('null'));
                serviceTimeStrategyNode.appendChild(subParValue);
            else
                distributionNode = simDoc.createElement('subParameter');
                distributionNode.setAttribute('classPath', distributionObj.javaClass);
                distributionNode.setAttribute('name', distributionObj.name);
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
                        case {'java.lang.Double'}
                            subParValue.appendChild(simDoc.createTextNode(sprintf('%f',distributionObj.getParam(k).paramValue)));
                        case {'java.lang.Long'}
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
end
