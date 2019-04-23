function [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode)
% [SIMDOC, SECTION] = SAVESERVICESTRATEGY(SELF, SIMDOC, SECTION, CURRENTNODE)

% Copyright (c) 2012-2019, Imperial College London
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
    elseif isa(distributionObj,'APH') || (isa(distributionObj,'Coxian') && distributionObj.getNumParams == 2) || (isa(distributionObj,'HyperExp')  && distributionObj.getNumParams == 2)
        % Coxian and HyperExp have 2 parameters when they have a {mu, p} input specification
        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
        distributionNode = simDoc.createElement('subParameter');
        distributionNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypeDistr');
        distributionNode.setAttribute('name', 'Phase-Type');
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypePar');
        distrParNode.setAttribute('name', 'distrPar');
        
        subParNodeAlpha = simDoc.createElement('subParameter');
        subParNodeAlpha.setAttribute('array', 'true');
        subParNodeAlpha.setAttribute('classPath', 'java.lang.Object');
        subParNodeAlpha.setAttribute('name', 'alpha');
        subParNodeAlphaVec = simDoc.createElement('subParameter');
        subParNodeAlphaVec.setAttribute('array', 'true');
        subParNodeAlphaVec.setAttribute('classPath', 'java.lang.Object');
        subParNodeAlphaVec.setAttribute('name', 'vector');
        PH=distributionObj.getRepresentation;
        alpha = map_pie(PH);
        for k=1:distributionObj.getNumberOfPhases
            subParNodeAlphaElem = simDoc.createElement('subParameter');
            subParNodeAlphaElem.setAttribute('classPath', 'java.lang.Double');
            subParNodeAlphaElem.setAttribute('name', 'entry');
            subParValue = simDoc.createElement('value');
            subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',alpha(k))));
            subParNodeAlphaElem.appendChild(subParValue);
            subParNodeAlphaVec.appendChild(subParNodeAlphaElem);
        end
        
        subParNodeT = simDoc.createElement('subParameter');
        subParNodeT.setAttribute('array', 'true');
        subParNodeT.setAttribute('classPath', 'java.lang.Object');
        subParNodeT.setAttribute('name', 'T');
        T = PH{1};
        for k=1:distributionObj.getNumberOfPhases
            subParNodeTvec = simDoc.createElement('subParameter');
            subParNodeTvec.setAttribute('array', 'true');
            subParNodeTvec.setAttribute('classPath', 'java.lang.Object');
            subParNodeTvec.setAttribute('name', 'vector');
            for j=1:distributionObj.getNumberOfPhases
                subParNodeTElem = simDoc.createElement('subParameter');
                subParNodeTElem.setAttribute('classPath', 'java.lang.Double');
                subParNodeTElem.setAttribute('name', 'entry');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',T(k,j))));
                subParNodeTElem.appendChild(subParValue);
                subParNodeTvec.appendChild(subParNodeTElem);
            end
            subParNodeT.appendChild(subParNodeTvec);
        end
        
        subParNodeAlpha.appendChild(subParNodeAlphaVec);
        distrParNode.appendChild(subParNodeAlpha);
        distrParNode.appendChild(subParNodeT);
        serviceTimeStrategyNode.appendChild(distributionNode);
        serviceTimeStrategyNode.appendChild(distrParNode);
    else
        serviceTimeStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        serviceTimeStrategyNode.setAttribute('name', 'ServiceTimeStrategy');
        
        distributionNode = simDoc.createElement('subParameter');
        switch class(distributionObj)
            case 'Det'
                javaClass = 'jmt.engine.random.DeterministicDistr';
                javaParClass = 'jmt.engine.random.DeterministicDistrPar';
            case 'Coxian'
                javaClass = 'jmt.engine.random.CoxianDistr';
                javaParClass = 'jmt.engine.random.CoxianPar';
            case 'Erlang'
                javaClass = 'jmt.engine.random.Erlang';
                javaParClass = 'jmt.engine.random.ErlangPar';
            case 'Exp'
                javaClass = 'jmt.engine.random.Exponential';
                javaParClass = 'jmt.engine.random.ExponentialPar';
            case 'Gamma'
                javaClass = 'jmt.engine.random.GammaDistr';
                javaParClass = 'jmt.engine.random.GammaDistrPar';
            case 'HyperExp'
                javaClass = 'jmt.engine.random.HyperExp';
                javaParClass = 'jmt.engine.random.HyperExpPar';
            case 'Pareto'
                javaClass = 'jmt.engine.random.Pareto';
                javaParClass = 'jmt.engine.random.ParetoPar';
            case 'Uniform'
                javaClass = 'jmt.engine.random.Uniform';
                javaParClass = 'jmt.engine.random.UniformPar';
            case 'MMPP2'
                javaClass = 'jmt.engine.random.MMPP2Distr';
                javaParClass = 'jmt.engine.random.MMPP2Par';
            case 'Replayer'
                javaClass = 'jmt.engine.random.Replayer';
                javaParClass = 'jmt.engine.random.ReplayerPar';
        end
        distributionNode.setAttribute('classPath', javaClass);
        switch distributionObj.name
            case 'Replayer'
                distributionNode.setAttribute('name', 'Replayer');
            case 'HyperExp'
                distributionNode.setAttribute('name', 'Hyperexponential');
            otherwise
                distributionNode.setAttribute('name', distributionObj.name);
        end
        serviceTimeStrategyNode.appendChild(distributionNode);
        
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', javaParClass);
        distrParNode.setAttribute('name', 'distrPar');
        
        for k=1:distributionObj.getNumParams()
            subParNodeAlpha = simDoc.createElement('subParameter');
            subParNodeAlpha.setAttribute('classPath', distributionObj.getParam(k).paramClass);
            subParNodeAlpha.setAttribute('name', distributionObj.getParam(k).paramName);
            subParValue = simDoc.createElement('value');
            switch distributionObj.getParam(k).paramClass
                case 'java.lang.Double'
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',distributionObj.getParam(k).paramValue)));
                case 'java.lang.Long'
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%d',distributionObj.getParam(k).paramValue)));
                case 'java.lang.String'
                    subParValue.appendChild(simDoc.createTextNode(distributionObj.getParam(k).paramValue));
            end
            subParNodeAlpha.appendChild(subParValue);
            distrParNode.appendChild(subParNodeAlpha);
        end
        
        serviceTimeStrategyNode.appendChild(distrParNode);
    end
    strategyNode.appendChild(serviceTimeStrategyNode);
    section.appendChild(strategyNode);
end
end


