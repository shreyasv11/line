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
            % SELF = STATIONSTATEAGGR(STATION, T, STATE_A)
            
            self.t = t;
            self.state = state_a;
            self.station = station;
        end
        
        function state = getTimestamps(self)
            % STATE = GETTIMESTAMPS(SELF)
            
            state = self.t;
        end
        
        function state = getStateAggr(self)
            % STATE = GETSTATEAGGR(SELF)
            
            state = self.state;
        end
        
    end
    
end
