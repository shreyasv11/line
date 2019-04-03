classdef DiscreteDistrib < Distrib
    % An abstract class for continuous distributions
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        function self = DiscreteDistrib(name, numParam, support)
            % Construct a continuous distribution from name, number of
            % parameters, and range
            self@Distrib(name,numParam,support);
        end
    end
    
end