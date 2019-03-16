classdef OutputSection < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        outputStrategy;
    end

    methods(Hidden)
        %Constructor
        function self = OutputSection(className)
            self@Section(className);
        end
    end
end
