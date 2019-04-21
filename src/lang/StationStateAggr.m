classdef StationStateAggr
    % Aggregate state
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        station; % station handle
        t; % timestamp
        state; % aggregate staion state
    end
    
    methods
        function self = StationStateAggr(station, t, state_a)
            self.t = t;
            self.state = state_a;
            self.station = station;
        end
        
        function state = getTimestamps(self)
            state = self.t;
        end
        
        function state = getStateAggr(self)
            state = self.state;
        end
        
    end
    
end