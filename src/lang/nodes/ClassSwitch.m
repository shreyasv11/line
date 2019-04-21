classdef ClassSwitch < Node
    % A node to change the class of visiting jobs
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        cap;
        schedPolicy;
        schedStrategy;
    end
    
    methods
        %Constructor
        function self = ClassSwitch(model, name, csMatrix)
            self@Node(name);
            
            classes = model.classes;
            self.input = Buffer(classes);
            self.output = Dispatcher(classes);
            self.cap = Inf;
            self.schedPolicy = SchedStrategyType.NP;
            self.schedStrategy = SchedStrategy.FCFS;
            self.server = StatelessClassSwitcher(classes, csMatrix);
            self.setModel(model);
            self.model.addNode(self);
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, RoutingStrategy.PROB, destination, probability);
        end
        
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
    end
    
end
