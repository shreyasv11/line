classdef JoinStation < Station
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

% The number of jobs inside JoinStation is interpreted as the number of
% jobs waiting to be joined with the sibling tasks.

    properties
        joinStrategy;
    end
    
    methods 
        %Constructor
        function self = JoinStation(model, name)
            self = self@Station(name);
            self.numberOfServers = 0;
            if(model ~= 0)
                classes = model.classes;
                self.input = Join(classes);
                self.output = Dispatcher(classes);
                self.server = ServiceTunnel();
                addNode(model, self);
            end
%             if ~exist('joinstrategy','var')
%                 joinstrategy = JoinStrategy.Standard;
%             end
%             setStrategy(joinstrategy);
        end
    end
        
    methods
        function self = setStrategy(self, class, strategy)
            self.input.setStrategy(class,strategy);
        end
        
        function self = setRequired(self, class, njobs)
            self.input.setRequired(class,njobs);
        end
        
        function self = setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
    end
    
end
