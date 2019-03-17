classdef ContinuousDistrib < Distrib
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods (Hidden)
        %Constructor
        function self = ContinuousDistrib(name, numParam, support)
            self = self@Distrib(name,numParam,support);
        end
    end
    
end

