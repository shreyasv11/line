classdef MarkovModulated < PointProcess
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = MarkovModulated(name, numParam)
            self@PointProcess(name, numParam);
        end
    end
    
    methods        
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRenewalProcess,n);
        end
    end
    
    methods (Abstract)
        phases = getNumberOfPhases(self);
        MAP = getRenewalProcess(self);
    end
    
    methods (Static)
        function cx = fit(MEAN, SCV)
            cx = Cox2.fitMeanAndSCV(MEAN,SCV);
        end
    end
    
end

