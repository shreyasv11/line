classdef Cache < StatefulNode
    % A class switch node based on cache hits or misses
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        cap;
        schedPolicy;
        schedStrategy;
        replacementPolicy;
        popularity;
        nLevels;
        itemLevelCap;
        items;
        accessCost;
    end
    
    methods
        %Constructor
        function self = Cache(model, name, nitems, itemLevelCap, replPolicy)
            self = self@StatefulNode(name);
            if ~exist('levels','var')
                levels = 1;
            end
            classes = model.classes;
            self.input = Buffer(classes);
            self.output = Dispatcher(classes);
            self.schedPolicy = SchedStrategyType.NP;
            self.schedStrategy = SchedStrategy.FCFS;
            self.items = ItemSet(model, [name,'_','Items'], nitems, self);
            self.nLevels = nnz(itemLevelCap);
            self.cap = Inf; % job capacity
            self.accessCost = {};
            self.itemLevelCap = itemLevelCap; % item capacity
            if sum(itemLevelCap) > nitems
                error('The number of items is smaller than the capacity of %s.',name);
            end
            self.replacementPolicy = ReplacementStrategy.toId(replPolicy);
            self.server =  CacheClassSwitcher(classes, levels, itemLevelCap); % replace Server created by Queue
            self.popularity = {};
            self.setModel(model);
            self.model.addNode(self);
        end
        
        %         function setMissTime(self, distribution)
        %             itemclass = self.items;
        %             self.server.serviceProcess{1, itemclass.index} = {[], ServiceStrategy.ID_SD, distribution};
        %         end
        %
        %         function setHitTime(self, distribution, level)
        %             itemclass = self.items;
        %             if ~exist('level','var')
        %                 levels = 2:self.nLevels;
        %             else
        %                 levels = level;
        %             end
        %             for level = levels
        %                 self.server.serviceProcess{1+level, itemclass.index} = {[], ServiceStrategy.ID_SD, distribution};
        %             end
        %         end
        
        function setHitClass(self, jobinclass, joboutclass)
            self.server.hitClass(jobinclass.index) = joboutclass.index;
        end
        
        function setMissClass(self, jobinclass, joboutclass)
            self.server.missClass(jobinclass.index) = joboutclass.index;
        end
        
        function setRead(self, jobclass, distribution)
            itemclass = self.items;
            if distribution.isDiscrete
                self.popularity{itemclass.index, jobclass.index} = distribution.copy;
                if self.popularity{itemclass.index, jobclass.index}.support(2) ~= itemclass.nitems
                    error('The reference model is defined on a number of items different from the ones used to instantiate %s.',self.name);
                end
                switch class(distribution)
                    case 'Zipf'
                        self.popularity{itemclass.index, jobclass.index}.setParam(2, 'n', itemclass.nitems, 'java.lang.Integer');
                end
                %                self.probselect(itemclass.index, jobclass.index) = probselect;
            else
                error('A discrete popularity distribution is required.');
            end
        end
        
        function setAccessCosts(self, R)
            self.accessCost = R;
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
    end
end