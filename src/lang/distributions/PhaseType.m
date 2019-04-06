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
        
        function MEAN = getMean(self)
            MEAN = map_mean(self.getRepresentation);
        end
        
        function SCV = getSCV(self)
            SCV = map_scv(self.getRepresentation);
        end
        
        function SKEW = getSkewness(self)
            SKEW = map_skew(self.getRepresentation);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        
        function update(self,varargin)
            % Update parameters to match given moments
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        
        function updateMean(self,MEAN)
            % Update parameters to match a given mean
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        
        function updateRate(self,RATE)
            % Update rate
            self.updateMean(1/RATE);
        end
        
        function self = updateMeanAndVar(self, MEAN, VAR)
            % Update distribution with given mean and variance
            SCV = VAR / MEAN^2;
            ex = self.fitMeanAndSCV(MEAN,SCV);
        end
        
        function self = updateMeanAndSCV(self, MEAN, SCV)
            % Update distribution with given mean and squared coefficient of
            % variation (SCV=variance/mean^2)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        
        function phases = getNumberOfPhases(self)
            % Return number of phases in the distribution
            PH = self.getRepresentation;
            phases = length(PH{1});
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
            e1 = MEAN;
            SCV = VAR / MEAN^2;
            e2 = (1+SCV)*e1^2;
            e3 = -(2*e1^3-3*e1*e2-SKEW*(e2-e1^2)^(3/2));
            [b,B]=APHFrom3Moments([e1,e2,e3]);
            A = eye(size(B));
            A(1,:) = b;
            alpha = b*inv(A);
            T = A*B*inv(A);
            ex = Coxian(alpha);
        end
    end
    
end

