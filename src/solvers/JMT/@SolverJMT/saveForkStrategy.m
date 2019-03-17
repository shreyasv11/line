function [simDoc, section] = saveForkStrategy(self, simDoc, section, currentNode)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

jplNode = simDoc.createElement('parameter');
jplNode.setAttribute('classPath', 'java.lang.Integer');
jplNode.setAttribute('name', 'jobsPerLink');
valueNode = simDoc.createElement('value');
valueNode.appendChild(simDoc.createTextNode(int2str(currentNode.output.tasksPerLink)));
jplNode.appendChild(valueNode);
section.appendChild(jplNode);

blockNode = simDoc.createElement('parameter');
blockNode.setAttribute('classPath', 'java.lang.Integer');
blockNode.setAttribute('name', 'block');
valueNode = simDoc.createElement('value');
valueNode.appendChild(simDoc.createTextNode(int2str(-1)));
blockNode.appendChild(valueNode);
section.appendChild(blockNode);

issimplNode = simDoc.createElement('parameter');
issimplNode.setAttribute('classPath', 'java.lang.Boolean');
issimplNode.setAttribute('name', 'isSimplifiedFork');
valueNode = simDoc.createElement('value');
valueNode.appendChild(simDoc.createTextNode('true'));
issimplNode.appendChild(valueNode);
section.appendChild(issimplNode);

strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategy');
strategyNode.setAttribute('name', 'ForkStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simDoc.createElement('refClass');
    refClassNode.appendChild(simDoc.createTextNode(currentClass.name));
    strategyNode.appendChild(refClassNode);
    
    concStratNode = simDoc.createElement('subParameter');
    concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.ProbabilitiesFork');
    concStratNode.setAttribute('name', 'Branch Probabilities');
    concStratNode2 = simDoc.createElement('subParameter');
    concStratNode2.setAttribute('array', 'true');
    concStratNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
    concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
    for k=1:length(currentNode.output.outputStrategy{i}{end})
        concStratNode3 = simDoc.createElement('subParameter');
        concStratNode3.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
        concStratNode3.setAttribute('name', 'OutPathEntry');
        concStratNode4 = simDoc.createElement('subParameter');
        concStratNode4.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode4.setAttribute('name', 'outUnitProbability');
        concStratNode4Station = simDoc.createElement('subParameter');
        concStratNode4Station.setAttribute('classPath', 'java.lang.String');
        concStratNode4Station.setAttribute('name', 'stationName');
        concStratNode4StationValueNode = simDoc.createElement('value');        
        if length(currentNode.output.outputStrategy{i}{end}) == 1
            concStratNode4StationValueNode.appendChild(simDoc.createTextNode('Random'));
        else
%            concStratNode4StationValueNode.appendChild(simDoc.createTextNode(sprintf('%s',RoutingStrategy.toText(currentNode.output.outputStrategy{i}{end}{k}{2}))));
            concStratNode4StationValueNode.appendChild(simDoc.createTextNode(sprintf('%s',RoutingStrategy.toText(currentNode.output.outputStrategy{i}{2}))));
        end
        concStratNode4Station.appendChild(concStratNode4StationValueNode);
        concStratNode3.appendChild(concStratNode4Station);
        concStratNode4Probability = simDoc.createElement('subParameter');
        concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
        concStratNode4Probability.setAttribute('name', 'probability');
        concStratNode4ProbabilityValueNode = simDoc.createElement('value');
        concStratNode4ProbabilityValueNode.appendChild(simDoc.createTextNode('1.0'));
        concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);
        
        concStratNode4b = simDoc.createElement('subParameter');
        concStratNode4b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode4b.setAttribute('array', 'true');
        concStratNode4b.setAttribute('name', 'JobsPerLinkDis');
        concStratNode5b = simDoc.createElement('subParameter');
        concStratNode5b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode5b.setAttribute('name', 'EmpiricalEntry');
        concStratNode5bStation = simDoc.createElement('subParameter');
        concStratNode5bStation.setAttribute('classPath', 'java.lang.String');
        concStratNode5bStation.setAttribute('name', 'numbers');
        concStratNode5bStationValueNode = simDoc.createElement('value');
        concStratNode5bStationValueNode.appendChild((simDoc.createTextNode(int2str(currentNode.output.tasksPerLink))));
        concStratNode5bStation.appendChild(concStratNode5bStationValueNode);
        concStratNode4b.appendChild(concStratNode5bStation);
        concStratNode5bProbability = simDoc.createElement('subParameter');
        concStratNode5bProbability.setAttribute('classPath', 'java.lang.Double');
        concStratNode5bProbability.setAttribute('name', 'probability');
        concStratNode5bProbabilityValueNode = simDoc.createElement('value');
        concStratNode5bProbabilityValueNode.appendChild(simDoc.createTextNode('1.0'));
        concStratNode5bProbability.appendChild(concStratNode5bProbabilityValueNode);
        
        concStratNode4.appendChild(concStratNode4Station);
        concStratNode4.appendChild(concStratNode4Probability);
        concStratNode3.appendChild(concStratNode4);
        concStratNode5b.appendChild(concStratNode5bStation);
        concStratNode5b.appendChild(concStratNode5bProbability);
        concStratNode4b.appendChild(concStratNode5b);
        concStratNode3.appendChild(concStratNode4b);
        concStratNode2.appendChild(concStratNode3);
        concStratNode.appendChild(concStratNode2);
        strategyNode.appendChild(concStratNode);
        section.appendChild(strategyNode);
    end
end
end
