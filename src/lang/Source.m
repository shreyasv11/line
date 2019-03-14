classdef Source < Station
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        schedStrategy;
    end
    
    methods
        %Constructor
        function self = Source(model, name)
            self = self@Station(name);
            self.numberOfServers = 1;
            if(model ~= 0)
                classes = model.classes;
				self.classCap = Inf*ones(1,length(classes));
                self.output = Dispatcher(classes);
                self.server = ServiceTunnel();
                self.input = RandomSource(classes);
                self.schedStrategy = SchedStrategy.EXT;
                self.setModel(model);
                addNode(model, self);
            end
        end
        
        function setArrival(self, class, distribution)
            self.input.sourceClasses{1, class.index}{2} = ServiceStrategy.LI;
            self.input.sourceClasses{1, class.index}{3} = distribution;
            if distribution.isDisabled()
                self.classCap(class.index) = 0;
            else
                self.classCap(class.index) = Inf;
            end
        end
        
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
    end
    
end