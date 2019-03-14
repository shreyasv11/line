classdef Sink < Node
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        schedStrategy;
    end
    
    methods
        %Constructor
        function self = Sink(model, name)
            self = self@Node(name);

            if model ~= 0
                self.input = '';
                self.output = '';
                self.server = Section('JobSink');
				self.setModel(model);
				self.model.addNode(self);
                self.schedStrategy = SchedStrategy.EXT;
            end
        end
                
        function sections = getSections(self)
            sections = {'', self.server, ''};
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            clone.input = self.input;
            clone.server = self.server.copy;
            clone.output = self.output;
        end
        
    end
    
end
