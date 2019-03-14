classdef Buffer < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        size;
        schedPolicy;
        inputJobClasses;
    end
    
    methods
        %Constructor
        function self = Buffer(classes)
            self = self@Section('Buffer');
            self.size = -1;
            self.schedPolicy = SchedPolicy.NP;
            self.inputJobClasses = {};
            initQueueJobClasses(self, classes);
        end
    end
    
    methods (Access = 'private')
        function initQueueJobClasses(self, customerClasses)
            for i = 1 : length(customerClasses)
                self.inputJobClasses{i} = {customerClasses{i}, SchedStrategy.FCFS, DropRule.InfiniteBuffer};
            end
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            for i = 1 : length(self.inputJobClasses)
                if ishandle(clone.inputJobClasses{i}{1})
                    % this is a problem if one modifies the classes in the
                    % model because the one below is not an handle so it
                    % will not be modified                    
                    clone.inputJobClasses{i}{1} = self.inputJobClasses{i}{1}.copy;
                end
            end
        end
    end
    
end

