classdef PhaseType < ContinuousDistrib
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = PhaseType(name, numParam)
            self@ContinuousDistrib(name, numParam, [0,Inf]);
        end
    end
    
    methods
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRenewalProcess,n);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function ex = fitMeanAndVar(self, MEAN, VAR)
			SCV = VAR / MEAN^2;
			ex = self.fitMeanAndSCV(MEAN,SCV);
		end		
        function ex = fitMeanAndSCV(self, MEAN, SCV)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
		end		
        function phases = getNumberOfPhases(self)
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

