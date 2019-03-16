classdef RandomSource < InputSection   
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
        sourceClasses;
    end
    
        methods
        %Constructor
        function self = RandomSource(classes)
            self = self@InputSection('RandomSource');
            for i = 1 : length(classes)
                self.sourceClasses{1,i} = {[],ServiceStrategy.LI,Disabled()};
            end
        end
    end
    
	    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            for i = 1 : length(self.sourceClasses)
                clone.sourceClasses{1,i}{3} = self.sourceClasses{1,i}{3}.copy;
            end
        end        
    end
    
end

