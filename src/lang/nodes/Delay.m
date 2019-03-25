classdef Delay < Queue
    % A service station without queueing
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Delay(model, name)
            self = self@Queue(model, name, SchedStrategy.INF);
            self.numberOfServers = Inf;
        end
    end
    
end

