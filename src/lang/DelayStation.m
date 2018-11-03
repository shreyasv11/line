classdef DelayStation < Queue
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        %       isThink;
    end
    
    methods
        %Constructor
        function self = DelayStation(model, name)
            self = self@Queue(model, name, SchedStrategy.INF);
            self.numberOfServers = Inf;
        end
    end
    
end
