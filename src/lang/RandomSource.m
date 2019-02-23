classdef RandomSource < Section   
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
        sourceClasses;
    end
    
        methods
        %Constructor
        function self = RandomSource(classes)
            self = self@Section('RandomSource');
            self.sourceClasses{1,1} = {[],ServiceStrategy.LI,Disabled()};
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

