classdef Cox < PhaseType
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods(Hidden) % At the moment this class cannot be run in JMT
        %Constructor
        function self = Cox(mu, phi)
            % mu(j) : rate of state j
            % phi(j): probability of completion in state j
            if phi(end)~=1 && isfinite(phi(end))
                error(sprintf('The completion probability in the last Cox state must be 1.0 but it is %0.1f',phi(end)));
            end
            self = self@PhaseType('Cox',2);
            self.setParam(1, 'mu', mu, 'java.lang.Double');
            self.setParam(2, 'phi', phi, 'java.lang.Double');
        end
    end
    
    methods
        function phases = getNumberOfPhases(self)
            phases  = length(self.getParam(1).paramValue);
        end
                
        function ex = getMean(self)
            mu = self.getMu();
            phi = self.getPhi();
            ex = map_mean({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]});
        end
        
        % SCV = Variance / Mean
        function ex = getSCV(self)
            mu = self.getMu();
            phi = self.getPhi();
            ex = map_scv({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]});
        end
        
        function PH = getRenewalProcess(self)
            mu = self.getMu();
            phi = self.getPhi();
            PH = {diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]};
        end
        
        function Ft = evalCDF(self,t)            
            mu = self.getMu();
            phi = self.getPhi();
            Ft = map_cdf({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]},t);
        end
        
        
        function mu = getMu(self)
            mu = self.getParam(1).paramValue(:);
        end
        
        function phi = getPhi(self)
            phi = self.getParam(2).paramValue(:);
        end
        
    end
    
    methods(Static)
        
        function [mu,phi] = fitMeanAndSCV(MEAN, SCV)
            % COXIAN finds a coxian representation (mu,phi) with specified mean and scv
            % mu:  nx1 vector of rates
            % phi: nx1 vector of completion probs
            % n: number of phases (optional parameter)
            
            if SCV >= 1-Distrib.Tol && SCV <= 1+Distrib.Tol
                n = 1;
                mu = 1/MEAN;
                phi = 1;
            elseif SCV > 0.5+Distrib.Tol && SCV<1-Distrib.Tol
                phi = 0.0;
                n = 2;
                mu = zeros(n,1);
                mu(1) = 2/MEAN/(1+sqrt(1+2*(SCV-1)));
                mu(2) = 2/MEAN/(1-sqrt(1+2*(SCV-1)));
            elseif SCV <= 0.5+Distrib.Tol
                n = ceil(1/SCV);
                lambda = n/MEAN;
                mu = lambda*ones(n,1);
                phi = zeros(n,1);
            else % SCV > 1+Distrib.Tol
                n = 2;
                %transform hyperexp into coxian
                mu = zeros(n,1);
                mu(1) = 2/MEAN;
                mu(2) = mu(1)/( 2*SCV );
                phi = zeros(n,1);
                phi(1) = 1 - mu(2)/mu(1);
                phi(2) = 1;
            end
            phi(n) = 1;
        end
    end
    
end

