function [simNode, section] = saveJoinStrategy(self, simNode, section, currentNode)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
strategyNode = simNode.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategy');
strategyNode.setAttribute('name', 'JoinStrategy');

numOfClasses = length(self.model.classes);
for i=1:(numOfClasses)
    currentClass = self.model.classes{i,1};
    switch currentNode.input.joinStrategy{currentClass.index}
        case JoinStrategy.Standard
            refClassNode2 = simNode.createElement('refClass');
            refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simNode.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.NormalJoin');
            joinStrategyNode.setAttribute('name', 'Standard Join');
            reqNode = simNode.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.input.joinRequired{currentClass.index})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
        case JoinStrategy.Quorum
            refClassNode2 = simNode.createElement('refClass');
            refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simNode.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
            joinStrategyNode.setAttribute('name', 'Quorum');
            reqNode = simNode.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.input.joinRequired{currentClass.index})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
        case JoinStrategy.Guard
            refClassNode2 = simNode.createElement('refClass');
            refClassNode2.appendChild(simNode.createTextNode(currentClass.name));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simNode.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
            joinStrategyNode.setAttribute('name', 'Quorum');
            reqNode = simNode.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simNode.createElement('value');
            valueNode.appendChild(simNode.createTextNode(int2str(currentNode.input.joinRequired{currentClass.index})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
    end
end
end
