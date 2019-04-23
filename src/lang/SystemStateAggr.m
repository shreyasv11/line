classdef SystemStateAggr
    % System state aggregated over the stations over time
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        model; % model handle
        t; % timestamp
        state; % joint system state
    end
    
    methods
        function self = SystemStateAggr(model, tranSysStateAggr)
            % SELF = SYSTEMSTATEAGGR(MODEL, TRANSYSSTATEAGGR)
            
            self.t = tranSysStateAggr{1};
            self.state = {tranSysStateAggr{2:end}};
            self.model = model;
        end
        
        function state = getTimestamps(self)
            % STATE = GETTIMESTAMPS(SELF)
            
            state = self.t;
        end
        
        function state = getJointStateAggr(self)
            % STATE = GETJOINTSTATEAGGR(SELF)
            
            state = cell2mat(self.state);
        end
    end
    
end
