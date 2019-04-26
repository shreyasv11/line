function fname = writeJSIM(self)
% FNAME = WRITEJSIM()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
[simElem, simDoc] = saveXMLHeader(self, self.model.getLogPath);
[simElem, simDoc] = saveClasses(self, simElem, simDoc);

numOfClasses = length(self.model.classes);
numOfNodes = length(self.model.nodes);
for i=1:(numOfNodes)
    currentNode = self.model.nodes{i,1};
    node = simDoc.createElement('node');
    node.setAttribute('name', currentNode.name);
    
    nodeSections = getSections(currentNode);
    for j=1:length(nodeSections)
        section = simDoc.createElement('section');
        currentSection = nodeSections{1,j};
        if ~isempty(currentSection)
            section.setAttribute('className', currentSection.className);
            switch currentSection.className
                case 'Buffer'
                    section.setAttribute('className', 'Queue'); %overwrite with JMT class name
                    [simDoc, section] = saveBufferCapacity(self, simDoc, section, currentNode);
                    [simDoc, section] = saveDropStrategy(self, simDoc, section);
                    [simDoc, section] = saveGetStrategy(self, simDoc, section, currentNode);
                    [simDoc, section] = savePutStrategy(self, simDoc, section, currentNode);
                case 'Server'
                    [simDoc, section] = saveNumberOfServers(self, simDoc, section, currentNode);
                    [simDoc, section] = saveServerVisits(self, simDoc, section);
                    [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode);
                case 'SharedServer'
                    section.setAttribute('className', 'PSServer'); %overwrite with JMT class name
                    [simDoc, section] = saveNumberOfServers(self, simDoc, section, currentNode);
                    [simDoc, section] = saveServerVisits(self, simDoc, section);
                    [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode);
                    [simDoc, section] = savePreemptiveStrategy(self, simDoc, section, currentNode);
                    [simDoc, section] = savePreemptiveWeights(self, simDoc, section, currentNode);
                case 'InfiniteServer'
                    section.setAttribute('className', 'Delay'); %overwrite with JMT class name
                    [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode);
                case 'LogTunnel'
                    [simDoc, section] = saveLogTunnel(self, simDoc, section, currentNode);
                case 'Dispatcher'
                    section.setAttribute('className', 'Router'); %overwrite with JMT class name
                    [simDoc, section] = saveRoutingStrategy(self, simDoc, section, currentNode);
                case 'StatelessClassSwitcher'
                    section.setAttribute('className', 'ClassSwitch'); %overwrite with JMT class name
                    [simDoc, section] = saveClassSwitchStrategy(self, simDoc, section, currentNode);
                case 'RandomSource'
                    [simDoc, section] = saveArrivalStrategy(self, simDoc, section, currentNode);
                case 'Joiner'
                    section.setAttribute('className', 'Join'); %overwrite with JMT class name
                    [simDoc, section] = saveJoinStrategy(self, simDoc, section, currentNode);
                case 'Forker'
                    section.setAttribute('className', 'Fork'); %overwrite with JMT class name
                    [simDoc, section] = saveForkStrategy(self, simDoc, section, currentNode);
            end
            node.appendChild(section);
        end
    end
    simElem.appendChild(node);
end

[simElem, simDoc] = saveMetrics(self, simElem, simDoc);
[simElem, simDoc] = saveLinks(self, simElem, simDoc);

hasReferenceNodes = 0;
preloadNode = simDoc.createElement('preload');
s0 = self.model.getState;
qn = self.model.getStruct;
numOfStations = length(self.model.stations);
for i=1:numOfStations
    isReferenceNode = 0;
    currentNode = self.model.nodes{qn.stationToNode(i),1};
    if (~isa(self.model.stations{i},'Source') && ~isa(self.model.stations{i},'Join'))
        [~, nir] = State.toMarginal(self.model,qn.stationToNode(i),s0{qn.stationToStateful(i)});
        stationPopulationsNode = simDoc.createElement('stationPopulations');
        stationPopulationsNode.setAttribute('stationName', currentNode.name);
        for r=1:(numOfClasses)
            currentClass = self.model.classes{r,1};
            %        if currentClass.isReferenceStation(currentNode)
            classPopulationNode = simDoc.createElement('classPopulation');
            switch currentClass.type
                case 'closed'
                    isReferenceNode = 1;
                    %                    classPopulationNode.setAttribute('population', sprintf('%d',currentClass.population));
                    classPopulationNode.setAttribute('population', sprintf('%d',round(nir(r))));
                    classPopulationNode.setAttribute('refClass', currentClass.name);
                    stationPopulationsNode.appendChild(classPopulationNode);
            end
            %        end
        end
    end
    if isReferenceNode
        preloadNode.appendChild(stationPopulationsNode);
    end
    hasReferenceNodes = hasReferenceNodes + isReferenceNode;
end
if hasReferenceNodes
    simElem.appendChild(preloadNode);
end
fname = getJSIMTempPath(self);
try
    xmlwrite(fname, simDoc);
catch
    javaaddpath(which('xercesImpl-2.11.0.jar'));
    javaaddpath(which('xml-apis-2.11.0.jar'));
    pkg load io;
    xmlwrite(fname, simDoc);
end
end
