function used = getUsedLangFeatures(self)
% USED = GETUSEDLANGFEATURES()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

self.initUsedFeatures;
% Get attributes
for i=1:self.getNumberOfNodes()
    for r=1:self.getNumberOfClasses()
        try % not all nodes have all classes
            switch class(self.nodes{i})
                case {'Queue','DelayStation'}
                    if ~isempty(self.nodes{i}.server.serviceProcess{r})
                        self.setUsedFeatures(self.nodes{i}.server.serviceProcess{r}{3}.name);
                        if self.nodes{i}.numberOfServers > 1
                            %self.setUsedFeatures('MultiServer')
                        end
                        self.setUsedFeatures(SchedStrategy.toFeature(self.nodes{i}.schedStrategy));
                        self.setUsedFeatures(RoutingStrategy.toFeature(self.nodes{i}.output.outputStrategy{r}{2}));
                    end
                case 'Router'
                    self.setUsedFeatures(RoutingStrategy.toFeature(self.nodes{i}.output.outputStrategy{r}{2}));
                case 'Source'
                    self.setUsedFeatures(self.nodes{i}.input.sourceClasses{r}{3}.name);
                    self.setUsedFeatures('OpenClass');
                case 'CacheNode'
                    self.setUsedFeatures('Cache');
                    self.setUsedFeatures('CacheNode');
                case 'ClassSwitch'
                    self.setUsedFeatures('StatelessClassSwitcher');
                    self.setUsedFeatures('ClassSwitch');
                case 'Fork'
                    self.setUsedFeatures('Fork');
                    self.setUsedFeatures('Forker');
                case 'Join'
                    self.setUsedFeatures('Join');
                    self.setUsedFeatures('Joiner');
            end
        end
    end
end
used = self.usedFeatures;
end
