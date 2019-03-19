classdef Cox2 < PhaseType
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Cox2(mu1, mu2, phi1)
            self = self@PhaseType('Coxian',3);
            setParam(self, 1, 'lambda0', mu1, 'java.lang.Double');
            setParam(self, 2, 'lambda1', mu2, 'java.lang.Double');
            setParam(self, 3, 'phi0', phi1, 'java.lang.Double'); % completion probability in phase 1
            self.javaClass = 'jmt.engine.random.CoxianDistr';
            self.javaParClass = 'jmt.engine.random.CoxianPar';
        end
        
        function phases = getNumberOfPhases(self)
            phases  = 2; %r
        end
        
        function ex = getMean(self)
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            ex = 1/mu1 + (1-phi1)/mu2;
        end
        
        function SCV = getSCV(self)
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            mean = 1/mu1 + (1-phi1)/mu2;
            var = ((2*mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (2*mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1))/(mu1*mu1*((mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1))) - (1/mu1 - (phi1 - 1)/mu2)*(1/mu1 - (phi1 - 1)/mu2) - (((phi1 - 1)/(mu2*mu2) + (phi1 - 1)/(mu1*mu2))*((2*mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (2*mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1)))/((mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1));
            SCV = var / mean^2;
        end
                
        function Ft = evalCDF(self, t)
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            Ft = 1- exp(-mu1*t)-(mu1.*(exp(-t*mu1) - exp(-t*(mu2))).*(1-phi1))./(mu2 - mu1);
        end
        
        function PH = getRenewalProcess(self)
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            PH={[-mu1,(1-phi1)*mu1;0,-mu2],[phi1*mu1,0;mu2,0]};
        end
        
    end
    
    methods(Static)
        function cx = fit(MEAN,SCV)
            cx = Cox2.fitMeanAndSCV(MEAN,SCV);
        end
        
        function cx = fitMeanAndSCV(MEAN, SCV)
            if (SCV <1 && SCV >=0.5)
                p = 0.0;
                l0 = 2/MEAN/(1+sqrt(1+2*(SCV-1)));
                l1 = 2/MEAN/(1-sqrt(1+2*(SCV-1)));
            elseif (SCV == 1.0)
                p = 1.0;
                l0 = 1/MEAN;
                l1 = 1/MEAN;
                cx = Exp(1/MEAN);
                return;
            else
                l0 = 2/MEAN;
                l1 = l0/(2*SCV);
                p = 1 - l1/l0;
            end
            cx = Cox2(l0,l1,p);
        end
        
    end
    
end