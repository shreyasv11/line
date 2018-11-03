function [simNode, section] = saveRoutingStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
strategyNode = simNode.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategy');
strategyNode.setAttribute('name', 'RoutingStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    strategyNode.appendChild(refClassNode);
    
    switch currentNode.output.outputStrategy{i}{2}
        case RoutingStrategy.RAND
            concStratNode = simNode.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RandomStrategy');
            concStratNode.setAttribute('name', 'Random');
        case RoutingStrategy.RR
            concStratNode = simNode.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RoundRobinStrategy');
            concStratNode.setAttribute('name', 'Round Robin');
        case RoutingStrategy.JSQ
            concStratNode = simNode.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.ShortestQueueLengthRoutingStrategy');
            concStratNode.setAttribute('name', 'Join the Shortest Queue (JSQ)');            
        case RoutingStrategy.PROB
            concStratNode = simNode.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.EmpiricalStrategy');
            concStratNode.setAttribute('name', 'Probabilities');
            concStratNode2 = simNode.createElement('subParameter');
            concStratNode2.setAttribute('array', 'true');
            concStratNode2.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
            concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
            for k=1:length(currentNode.output.outputStrategy{i}{end})
                concStratNode3 = simNode.createElement('subParameter');
                concStratNode3.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                concStratNode3.setAttribute('name', 'EmpiricalEntry');
                concStratNode4Station = simNode.createElement('subParameter');
                concStratNode4Station.setAttribute('classPath', 'java.lang.String');
                concStratNode4Station.setAttribute('name', 'stationName');
                concStratNode4StationValueNode = simNode.createElement('value');
                concStratNode4StationValueNode.appendChild(simNode.createTextNode(sprintf('%s',currentNode.output.outputStrategy{i}{end}{k}{1}.name)));
                concStratNode4Station.appendChild(concStratNode4StationValueNode);
                concStratNode3.appendChild(concStratNode4Station);
                concStratNode4Probability = simNode.createElement('subParameter');
                concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
                concStratNode4Probability.setAttribute('name', 'probability');
                concStratNode4ProbabilityValueNode = simNode.createElement('value');
                concStratNode4ProbabilityValueNode.appendChild(simNode.createTextNode(sprintf('%12.12f',currentNode.output.outputStrategy{i}{end}{k}{2})));
                concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);
                
                concStratNode3.appendChild(concStratNode4Station);
                concStratNode3.appendChild(concStratNode4Probability);
                concStratNode2.appendChild(concStratNode3);
            end
            concStratNode.appendChild(concStratNode2);
        otherwise
            concStratNode = simNode.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RandomStrategy');
            concStratNode.setAttribute('name', 'Random');
    end
    strategyNode.appendChild(concStratNode);
    section.appendChild(strategyNode);
end
end