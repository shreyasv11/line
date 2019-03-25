classdef MarkovModulated < PointProcess
    % An abstract class for Markov-modulated processes
    %
    % Copyright (c) 2012-Present, Imperial College London
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
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function phases = getNumberOfPhases(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function MAP = getRenewalProcess(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods (Static)
        function cx = fit(MEAN, SCV)
            cx = Cox2.fitMeanAndSCV(MEAN,SCV);
        end
    end
    
end

