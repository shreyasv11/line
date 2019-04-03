classdef PhaseType < ContinuousDistrib
    % An astract class for phase-type distributions
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        function self = PhaseType(name, numParam)
            % Abstract class constructor
            self@ContinuousDistrib(name, numParam, [0,Inf]);
        end
    end
    
    methods
        function X = sample(self, n)
            % Get n samples from the distribution
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRepresentation,n);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        
        function ex = fitMeanAndVar(self, MEAN, VAR)
            % Fit distribution with given mean and variance
            SCV = VAR / MEAN^2;
            ex = self.fitMeanAndSCV(MEAN,SCV);
        end
        
        function ex = fitMeanAndSCV(self, MEAN, VAR)
            % Fit phase-type distribution with given mean and squared coefficient of
            % variation (SCV=variance/mean^2)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function phases = getNumberOfPhases(self)
            % Return number of phases in the distribution
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        
        function PH = getRepresentation(self)
            % Return the renewal process associated to the distribution
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        
        function L = evalLaplaceTransform(self, s)
            % Evaluate the Laplace transform of the distribution function at t            
            PH = self.getRepresentation;
            pie = map_pie(PH);
            A = PH{1};
            e = ones(length(pie),1);
            L = pie*inv(s*eye(size(A))-A)*(-A)*e;
        end
    end
    
    methods (Static)
        function ex = fit(MEAN, VAR, SKEW)
            % Fit the distribution from first three central moments (mean,
            % variance, skewness)
            cx = Cox2.fit(MEAN,VAR, SKEW);
        end
    end
    
end

