classdef Prior < Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        name;
        distribution;
    end
    
    methods%(Abstract)
        function bool = isDisabled(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
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

