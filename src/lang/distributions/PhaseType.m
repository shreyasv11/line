classdef PhaseType < Distrib
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = PhaseType(name, numParam)
            self@Distrib(name, numParam, [0,Inf]);
        end
    end
    
    methods
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRenewalProcess,n);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function phases = getNumberOfPhases()
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function PH = getRenewalProcess(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods (Static)
        function cx = fit(MEAN, SCV)
            cx = Cox2.fitMeanAndSCV(MEAN,SCV);
        end
    end
    
end

