classdef Prior < matlab.mixin.Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        name;
        distribution;
    end
    
    methods(Abstract)
        bool = isDisabled(self);
    end    
    
    methods (Hidden)
        %Constructor
        function self = Prior(distribution)
            self.name = 'Prior';
            self.distribution = distribution;
        end
        
        function X = sample(self)
           X = self.distribution.sample();
        end
    end
    
end

