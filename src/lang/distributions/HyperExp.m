classdef HyperExp < PhaseType
    % The hyper-exponential statistical distribution
    %
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = HyperExp(p, lambda1, lambda2)
            self = self@PhaseType('HyperExp',3);
            setParam(self, 1, 'p', p, 'java.lang.Double');
            setParam(self, 2, 'lambda1', lambda1, 'java.lang.Double');
            setParam(self, 3, 'lambda2', lambda2, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.HyperExp';
            self.javaParClass = 'jmt.engine.random.HyperExpPar';
        end
        
        function phases = getNumberOfPhases(self)
            phases  = 2; %r
        end        
        
        function ex = getMean(self)
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            ex = p/mu1 + (1-p)/mu2;
        end
        
        function SCV = getSCV(self)
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            SCV = (2*(p/mu1^2 + (1-p)/mu2^2) - (p/mu1 + (1-p)/mu2)^2)/(p/mu1 + (1-p)/mu2)^2;
        end
                
        function Ft = evalCDF(self,t)
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            Ft = p*(1-exp(-mu1*t))+(1-p)*(1-exp(-mu2*t));
        end
        
        function PH = getRenewalProcess(self)
            p = self.getParam(1).paramValue;
            mu1 = self.getParam(2).paramValue;
            mu2 = self.getParam(3).paramValue;
            PH={[-mu1,0;0,-mu2],[mu1*p,mu1*(1-p);mu2*p,mu2*(1-p)]};
        end
        
    end
    
    methods(Static)
        function he = fit(MEAN,SCV)
            he = HyperExp.fitMeanAndSCV(MEAN,SCV);
        end
        
        function he = fitMeanAndSCV(MEAN, SCV)
            [~,mu1,mu2,p]=map_hyperexp(MEAN,SCV);
            he = HyperExp(p, mu1, mu2);
        end
        
    end
    
end

