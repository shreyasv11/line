classdef HyperExp < PhaseType
    % The hyper-exponential statistical distribution
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = HyperExp(p, lambda1, lambda2)
            % Constructs a two-phase exponential distribution from
            % probability of selecting phase 1 and the two phase rates
            self@PhaseType('HyperExp',3);           
            setParam(self, 1, 'p', p, 'java.lang.Double');
            setParam(self, 2, 'lambda1', lambda1, 'java.lang.Double');
            setParam(self, 3, 'lambda2', lambda2, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.HyperExp';
            self.javaParClass = 'jmt.engine.random.HyperExpPar';
        end
        
        function phases = getNumberOfPhases(self)
            % Get number of phases in the underpinnning phase-type
            % representation
            phases  = 2; %r
        end
        
        function ex = getMean(self)
            % Get distribution mean
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            ex = p/mu1 + (1-p)/mu2;
        end
        
        function SCV = getSCV(self)
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)                    
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            SCV = (2*(p/mu1^2 + (1-p)/mu2^2) - (p/mu1 + (1-p)/mu2)^2)/(p/mu1 + (1-p)/mu2)^2;
        end
        
        function Ft = evalCDF(self,t)
            % Evaluate the cumulative distribution function at t
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            Ft = p*(1-exp(-mu1*t))+(1-p)*(1-exp(-mu2*t));
        end
        
        function PH = getRepresentation(self)
            % Return the renewal process associated to the distribution            
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            PH={[-mu1,0;0,-mu2],[mu1*p,mu1*(1-p);mu2*p,mu2*(1-p)]};
        end
        
    end
    
    methods(Static)
        function he = fit(MEAN, VAR, SKEW)
            % Fit distribution from first three central moments (mean,
            % variance, skewness)
            SCV = VAR/MEAN^2;
            he = HyperExp.fitMeanAndSCV(MEAN,SCV);
        end
        
        function he = fitRate(RATE)
            % Fit distribution with given rate
            he = HyperExp(p, RATE, RATE);
        end
        
        function he = fitMean(MEAN)
            % Fit distribution with given mean
            he = HyperExp(p, 1/MEAN, 1/MEAN);
        end
        
        function he = fitMeanAndSCV(MEAN, SCV)
            % Fit distribution with given mean and squared coefficient of variation (SCV=variance/mean^2)
            [~,mu1,mu2,p]=map_hyperexp(MEAN,SCV);
            he = HyperExp(p, mu1, mu2);
        end
        
    end
    
end

