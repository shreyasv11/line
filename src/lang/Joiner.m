classdef Joiner < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        joinStrategy;
        joinRequired;
        joinJobClasses;
    end
    
    methods
        %Constructor
        function self = Joiner(customerClasses)
            self = self@Section('Joiner');
            self.joinJobClasses = {};
            initJoinJobClasses(self, customerClasses);
        end
    end
    
    methods (Access = 'public')
        
        function setRequired(self, customerClass, nJobs)
            self.joinRequired{customerClass.index} = nJobs;
        end
        
        function setStrategy(self, customerClass, joinStrat)
            self.joinJobClasses{customerClass.index} = customerClass;            
            self.joinStrategy{customerClass.index} = joinStrat;
        end
        
        function initJoinJobClasses(self, customerClasses)
            for i = 1 : length(customerClasses)
                self.joinJobClasses{i} = customerClasses{i};
                self.joinRequired{i} = -1;
                self.joinStrategy{i} = JoinStrategy.Standard;
            end
        end
    end

    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            for i=1:length(self.joinJobClasses)
                clone.joinJobClasses{i} = self.joinJobClasses{i}.copy;
            end
        end        
    end
    
end

