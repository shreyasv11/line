function [simNode, section] = saveArrivalStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

strategyNode = simNode.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
strategyNode.setAttribute('name', 'ServiceStrategy');

numOfClasses = length(self.model.classes);
for i=1:numOfClasses
    currentClass = self.model.classes{i,1};
    switch currentClass.type
        case 'closed'
            refClassNode2 = simNode.createElement('refClass');
            refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simNode.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            subParValue = simNode.createElement('value');
            subParValue.appendChild(simNode.createTextNode('null'));
            serviceTimeStrategyNode.appendChild(subParValue);
            strategyNode.appendChild(serviceTimeStrategyNode);
            section.appendChild(strategyNode);
            
        case 'open'
            refClassNode2 = simNode.createElement('refClass');
            refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            serviceTimeStrategyNode = simNode.createElement('subParameter');
            serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
            serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
            
            distributionObj = currentNode.input.sourceClasses{i}{3};
            if isempty(distributionObj.javaParClass) % Disabled distribution
                subParValue = simNode.createElement('value');
                subParValue.appendChild(simNode.createTextNode('null'));
                serviceTimeStrategyNode.appendChild(subParValue);
            else
                distributionNode = simNode.createElement('subParameter');
                distributionNode.setAttribute('classPath', distributionObj.javaClass);
                distributionNode.setAttribute('name', distributionObj.name);
                serviceTimeStrategyNode.appendChild(distributionNode);
                distrParNode = simNode.createElement('subParameter');
                distrParNode.setAttribute('classPath', distributionObj.javaParClass);
                distrParNode.setAttribute('name', 'distrPar');
                
                for k=1:distributionObj.getNumParams()
                    subParNode = simNode.createElement('subParameter');
                    subParNode.setAttribute('classPath', distributionObj.getParam(k).paramClass);
                    subParNode.setAttribute('name', distributionObj.getParam(k).paramName);
                    subParValue = simNode.createElement('value');
                    switch distributionObj.getParam(k).paramClass
                        case {'java.lang.Double'}
                            subParValue.appendChild(simNode.createTextNode(sprintf('%f',distributionObj.getParam(k).paramValue)));
                        case {'java.lang.Long'}
                            subParValue.appendChild(simNode.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                        case 'java.lang.String'
                            subParValue.appendChild(simNode.createTextNode(distributionObj.getParam(k).paramValue));
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
