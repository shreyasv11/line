function [simNode, section] = saveForkStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

jplNode = simNode.createElement('parameter');
jplNode.setAttribute('classPath', 'java.lang.Integer');
jplNode.setAttribute('name', 'jobsPerLink');
valueNode = simNode.createElement('value');
valueNode.appendChild(simNode.createTextNode(int2str(currentNode.output.tasksPerLink)));
jplNode.appendChild(valueNode);
section.appendChild(jplNode);

blockNode = simNode.createElement('parameter');
blockNode.setAttribute('classPath', 'java.lang.Integer');
blockNode.setAttribute('name', 'block');
valueNode = simNode.createElement('value');
valueNode.appendChild(simNode.createTextNode(int2str(-1)));
blockNode.appendChild(valueNode);
section.appendChild(blockNode);

issimplNode = simNode.createElement('parameter');
issimplNode.setAttribute('classPath', 'java.lang.Boolean');
issimplNode.setAttribute('name', 'isSimplifiedFork');
valueNode = simNode.createElement('value');
valueNode.appendChild(simNode.createTextNode('true'));
issimplNode.appendChild(valueNode);
section.appendChild(issimplNode);

strategyNode = simNode.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategy');
strategyNode.setAttribute('name', 'ForkStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    
    refClassNode = simNode.createElement('refClass');
    refClassNode.appendChild(simNode.createTextNode(currentClass.name));
    strategyNode.appendChild(refClassNode);
    
    concStratNode = simNode.createElement('subParameter');
    concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.PROBFork');
    concStratNode.setAttribute('name', 'Branch Probabilities');
    concStratNode2 = simNode.createElement('subParameter');
    concStratNode2.setAttribute('array', 'true');
    concStratNode2.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
    concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
    for k=1:length(currentNode.output.outputStrategy{i}{end})
        concStratNode3 = simNode.createElement('subParameter');
        concStratNode3.setAttribute('classPath', 'jmt.engine.NetStrategies.ForkStrategies.OutPath');
        concStratNode3.setAttribute('name', 'OutPathEntry');
        concStratNode4 = simNode.createElement('subParameter');
        concStratNode4.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode4.setAttribute('name', 'outUnitProbability');
        concStratNode4Station = simNode.createElement('subParameter');
        concStratNode4Station.setAttribute('classPath', 'java.lang.String');
        concStratNode4Station.setAttribute('name', 'stationName');
        concStratNode4StationValueNode = simNode.createElement('value');        
        if length(currentNode.output.outputStrategy{i}{end}) == 1
            concStratNode4StationValueNode.appendChild(simNode.createTextNode('Random'));
        else
            concStratNode4StationValueNode.appendChild(simNode.createTextNode(sprintf('%s',RoutingStrategy.toText(currentNode.output.outputStrategy{i}{end}{k}{2}))));
        end
        concStratNode4Station.appendChild(concStratNode4StationValueNode);
        concStratNode3.appendChild(concStratNode4Station);
        concStratNode4Probability = simNode.createElement('subParameter');
        concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
        concStratNode4Probability.setAttribute('name', 'probability');
        concStratNode4ProbabilityValueNode = simNode.createElement('value');
        concStratNode4ProbabilityValueNode.appendChild(simNode.createTextNode('1.0'));
        concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);
        
        concStratNode4b = simNode.createElement('subParameter');
        concStratNode4b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode4b.setAttribute('array', 'true');
        concStratNode4b.setAttribute('name', 'JobsPerLinkDis');
        concStratNode5b = simNode.createElement('subParameter');
        concStratNode5b.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
        concStratNode5b.setAttribute('name', 'EmpiricalEntry');
        concStratNode5bStation = simNode.createElement('subParameter');
        concStratNode5bStation.setAttribute('classPath', 'java.lang.String');
        concStratNode5bStation.setAttribute('name', 'numbers');
        concStratNode5bStationValueNode = simNode.createElement('value');
        concStratNode5bStationValueNode.appendChild(simNode.createTextNode('1'));
        concStratNode5bStation.appendChild(concStratNode5bStationValueNode);
        concStratNode4b.appendChild(concStratNode5bStation);
        concStratNode5bProbability = simNode.createElement('subParameter');
        concStratNode5bProbability.setAttribute('classPath', 'java.lang.Double');
        concStratNode5bProbability.setAttribute('name', 'probability');
        concStratNode5bProbabilityValueNode = simNode.createElement('value');
        concStratNode5bProbabilityValueNode.appendChild(simNode.createTextNode('1.0'));
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
