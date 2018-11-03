classdef Fork < Section
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        routerStrategy;
        tasksPerLink;
    end
    
    methods
        %Constructor
        function self = Fork(customerClasses)
            self = self@Section('Fork');
            self.outputStrategy= {};
            self.tasksPerLink=1.0;
            initDispatcherJobClasses(self, customerClasses);
        end
    end
    
    methods (Access = 'private')
        function initDispatcherJobClasses(self, customerClasses)
           for i = 1 : length(customerClasses)
              self.outputStrategy{i} = {customerClasses{i}.name, RoutingStrategy.RAND};  
           end
        end
    end
	
       methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@matlab.mixin.Copyable(self);
            % Make a deep copy of each object
            for i = 1 : length(self.outputStrategy)
                if ishandle(clone.outputStrategy{i}{1})
                    % this is a problem if one modifies the classes in the
                    % model because the one below is not an handle so it
                    % will not be modified                    
                    clone.outputStrategy{i}{1} = self.outputStrategy{i}{1}.copy;
                end
            end
        end
    end
end
