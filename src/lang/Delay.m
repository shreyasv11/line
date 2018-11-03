classdef Delay < DelayStation
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        %       isThink;
    end
    
    methods
        %Constructor
        function self = Delay(model, name)
            self = self@DelayStation(model, name);
        end
    end
    
end
