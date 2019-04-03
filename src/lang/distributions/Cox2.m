classdef Cox2 < PhaseType
    % The two-phase coxian statistical distribution
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = Cox2(mu1, mu2, phi1)
            % Constructs a 2-phase Coxian distribution from phase rates and
            % completion probability
            self@PhaseType('Cox2',3);
            setParam(self, 1, 'lambda0', mu1, 'java.lang.Double');
            setParam(self, 2, 'lambda1', mu2, 'java.lang.Double');
            setParam(self, 3, 'phi0', phi1, 'java.lang.Double'); % completion probability in phase 1
            self.javaClass = 'jmt.engine.random.CoxianDistr';
            self.javaParClass = 'jmt.engine.random.CoxianPar';
        end
        
        function phases = getNumberOfPhases(self)
            % Return number of phases in the distribution
            phases  = 2; %r
        end
        
        function ex = getMean(self)
            % Get distribution mean
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            ex = 1/mu1 + (1-phi1)/mu2;
        end
        
        function SCV = getSCV(self)
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            mean = 1/mu1 + (1-phi1)/mu2;
            var = ((2*mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (2*mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1))/(mu1*mu1*((mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1))) - (1/mu1 - (phi1 - 1)/mu2)*(1/mu1 - (phi1 - 1)/mu2) - (((phi1 - 1)/(mu2*mu2) + (phi1 - 1)/(mu1*mu2))*((2*mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (2*mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1)))/((mu2*(mu1 - mu1*phi1))/(mu1 + mu2 - mu1*phi1) + (mu1*mu2*phi1)/(mu1 + mu2 - mu1*phi1));
            SCV = var / mean^2;
        end
        
        function Ft = evalCDF(self, t)
            % Evaluate the cumulative distribution function at t
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            Ft = 1- exp(-mu1*t)-(mu1.*(exp(-t*mu1) - exp(-t*(mu2))).*(1-phi1))./(mu2 - mu1);
        end
        
        function PH = getRepresentation(self)
            % Return the renewal process associated to the distribution
            mu1 = self.getParam(1).paramValue;
            mu2 = self.getParam(2).paramValue;
            phi1 = self.getParam(3).paramValue;
            PH={[-mu1,(1-phi1)*mu1;0,-mu2],[phi1*mu1,0;mu2,0]};
        end
    end
    
    methods(Static)
        function cx = fit(MEAN,SCV,SKEW)
            % Fit the distribution from first three central moments (mean,
            % variance, skewness)
            if nargin == 2
                cx = Cox2.fitMeanAndSCV(MEAN,SCV);
                return
            end
            e1 = MEAN;
            e2 = (1+SCV)*e1^2;
            e3 = -(2*e1^3-3*e1*e2-SKEW*(e2-e1^2)^(3/2));
            % consider the two possible solutions
            phi = (6*e1^3 - 6*e2*e1 + e3)/(- 6*e1^3 + 3*e2*e1);
            mu1 = [
                (2*(e3 - 3*e1*e2))/(- 3*e2^2 + 2*e1*e3) + (3*e1*e2 - e3 + (24*e1^3*e3 - 27*e1^2*e2^2 - 18*e1*e2*e3 + 18*e2^3 + e3^2)^(1/2))/(- 3*e2^2 + 2*e1*e3)
                (2*(e3 - 3*e1*e2))/(- 3*e2^2 + 2*e1*e3) - (e3 - 3*e1*e2 + (24*e1^3*e3 - 27*e1^2*e2^2 - 18*e1*e2*e3 + 18*e2^3 + e3^2)^(1/2))/(- 3*e2^2 + 2*e1*e3)
                ];
            mu2 = [
                -(3*e1*e2 - e3 + (24*e1^3*e3 - 27*e1^2*e2^2 - 18*e1*e2*e3 + 18*e2^3 + e3^2)^(1/2))/(- 3*e2^2 + 2*e1*e3)
                (e3 - 3*e1*e2 + (24*e1^3*e3 - 27*e1^2*e2^2 - 18*e1*e2*e3 + 18*e2^3 + e3^2)^(1/2))/(- 3*e2^2 + 2*e1*e3)];
            if phi>=0 && phi<=1 && mu1(1) >= 0 && mu2(1) >= 0
                % if the first solution is feasible
                cx = Cox2(mu1(1),mu2(1),phi);
            elseif phi >=0 && phi <=1 && mu1(2) >= 0 && mu2(2) >= 0
                % if the second solution is feasible
                cx = Cox2(mu1(2),mu2(2),phi);
            else
                % fit is not feasible
                if SCV>0.5
                    warning('Infeasible combination of central moments, fitting only mean and squared coefficient of variation.');
                    cx = Cox2.fitMeanAndSCV(MEAN, SCV);
                else
                    warning('Infeasible combination of central moments, fitting only mean.');
                    cx = Exp.fitMean(MEAN);
                end
            end
        end
        
        function cx = fitMeanAndSCV(MEAN, SCV)
            % Fit a 2-phase Coxian distribution with given mean and squared coefficient of variation (SCV=variance/mean^2)
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