classdef ServiceSection < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        numberOfServers;
        serviceProcess;
    end

    methods(Hidden)
        %Constructor
        function self = ServiceSection(className)
            self@Section(className);
        end
    end
end
