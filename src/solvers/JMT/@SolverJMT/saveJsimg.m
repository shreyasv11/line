function saveJsimg(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
[simElem, simNode] = saveXMLHeader(self, self.model.getLogPath);
[simElem, simNode] = saveClasses(self, simElem, simNode);

numOfClasses = length(self.model.classes);
numOfStations = length(self.model.nodes);
for i=1:(numOfStations)
    currentNode = self.model.nodes{i,1};
    node = simNode.createElement('node');
    node.setAttribute('name', currentNode.name);
    
    nodeSections = getSections(currentNode);
    for j=1:length(nodeSections)
        section = simNode.createElement('section');
        currentSection = nodeSections{1,j};
        if ~isempty(currentSection)
            section.setAttribute('className', currentSection.className);
            switch currentSection.className
                case 'Buffer'
                    section.setAttribute('className', 'Queue'); %overwrite with JMT class name
                    [simNode, section] = saveBufferCapacity(self, simNode, section, currentNode);
                    [simNode, section] = saveDropStrategy(self, simNode, section);
                    [simNode, section] = saveGetStrategy(self, simNode, section, currentNode);
                    [simNode, section] = savePutStrategy(self, simNode, section, currentNode);
                case 'Server'
                    [simNode, section] = saveNumberOfServers(self, simNode, section, currentNode);
                    [simNode, section] = saveServerVisits(self, simNode, section);
                    [simNode, section] = saveServiceStrategy(self, simNode, section, currentNode);
                case 'SharedServer'
                    section.setAttribute('className', 'PSServer'); %overwrite with JMT class name
                    [simNode, section] = saveNumberOfServers(self, simNode, section, currentNode);
                    [simNode, section] = saveServerVisits(self, simNode, section);
                    [simNode, section] = saveServiceStrategy(self, simNode, section, currentNode);
                    [simNode, section] = savePreemptiveStrategy(self, simNode, section, currentNode);
                    [simNode, section] = savePreemptiveWeights(self, simNode, section, currentNode);
                case 'InfiniteServer'
                    section.setAttribute('className', 'Delay'); %overwrite with JMT class name
                    [simNode, section] = saveServiceStrategy(self, simNode, section, currentNode);
                case 'LogTunnel'
                    [simNode, section] = saveLogTunnel(self, simNode, section, currentNode);
                case 'Dispatcher'
                    section.setAttribute('className', 'Router'); %overwrite with JMT class name
                    [simNode, section] = saveRoutingStrategy(self, simNode, section, currentNode);
                case 'StatelessClassSwitch'
                    section.setAttribute('className', 'ClassSwitch'); %overwrite with JMT class name
                    [simNode, section] = saveClassSwitchStrategy(self, simNode, section, currentNode);
                case 'RandomSource'
                    [simNode, section] = saveArrivalStrategy(self, simNode, section, currentNode);
                case 'Join'
                    [simNode, section] = saveJoinStrategy(self, simNode, section, currentNode);
                case 'Fork'
                    [simNode, section] = saveForkStrategy(self, simNode, section, currentNode);
            end
            node.appendChild(section);
        end
    end
    simElem.appendChild(node);
end

[simElem, simNode] = savePerfIndexes(self, simElem, simNode);
[simElem, simNode] = saveLinks(self, simElem, simNode);

hasReferenceNodes = 0;
preloadNode = simNode.createElement('preload');
s0 = self.model.getState;
qn = self.model.getStruct;
for i=1:numOfStations
    isReferenceNode = 0;
    currentNode = self.model.nodes{i,1};
    if i<=self.model.getNumberOfStations && (~isa(self.model.stations{i},'Source') && ~isa(self.model.stations{i},'Sink'))
        [~, nir] = State.toMarginal(self.model,qn.stationToNode(i),s0{qn.stationToStateful(i)});
        stationPopulationsNode = simNode.createElement('stationPopulations');
        stationPopulationsNode.setAttribute('stationName', currentNode.name);
        for r=1:(numOfClasses)
            currentClass = self.model.classes{r,1};
            %        if currentClass.isReferenceStation(currentNode)
            classPopulationNode = simNode.createElement('classPopulation');
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

%             docNode = com.mathworks.xml.XMLUtils.createDocument('archive');
%             docElem = docNode.getDocumentElement;
%             docElem.setAttribute('version', '1.0');
%             docElem.setAttribute('encoding', 'ISO-8859-1');
%             docElem.setAttribute('standalone', 'no');
%             docElem.setAttribute('xmlns:xsi', self.xmlnsXsi);
%             docElem.setAttribute('name', self.model.getName);
%             docElem.setAttribute('xsi:noNamespaceSchemaLocation', 'Archive.xsd');
%             docElem.appendChild(simNode);

xmlwrite(getJsimgtempPath(self), simNode);
end
