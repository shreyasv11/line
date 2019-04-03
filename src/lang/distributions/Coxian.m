classdef Coxian < PhaseType
    % The coxian statistical distribution
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = Coxian(mu, phi)
            % Constructs a Coxian distribution from phase rates and
            % completion probabilities, with entry probability 1 on the
            % first phase
            self@PhaseType('Coxian',2);
            % mu(j) : rate of state j
            % phi(j): probability of completion in state j
            if phi(end)~=1 && isfinite(phi(end))
                error('The completion probability in the last Cox state must be 1.0 but it is %0.1f',phi(end));
            end
            self.setParam(1, 'mu', mu, 'java.lang.Double');
            self.setParam(2, 'phi', phi, 'java.lang.Double');
        end
    end
    
    methods
        function phases = getNumberOfPhases(self)
            % Return number of phases in the distribution
            phases  = length(self.getParam(1).paramValue);
        end
        
        function ex = getMean(self)
            % Get distribution mean
            mu = self.getMu();
            phi = self.getPhi();
            ex = map_mean({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]});
        end
        
        function ex = getSCV(self)
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            mu = self.getMu();
            phi = self.getPhi();
            ex = map_scv({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]});
        end
        
        function PH = getRepresentation(self)
            % Return the renewal process associated to the distribution
            mu = self.getMu();
            phi = self.getPhi();
            PH = {diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]};
        end
        
        function Ft = evalCDF(self,t)
            % Evaluate the cumulative distribution function at t
            mu = self.getMu();
            phi = self.getPhi();
            Ft = map_cdf({diag(-mu)+diag(mu(1:end-1).*(1-phi(1:end-1)),1),[phi.*mu,zeros(length(mu),length(mu)-1)]},t);
        end
        
        function mu = getMu(self)
            % Get vector of rates
            mu = self.getParam(1).paramValue(:);
        end
        
        function phi = getPhi(self)
            % Get vector of completion probabilities
            phi = self.getParam(2).paramValue(:);
        end
        
    end
    
    methods(Static)
        
        function [mu,phi] = fitMeanAndSCV(MEAN, SCV)
            % Fit a Coxian distribution with given mean and squared coefficient of variation (SCV=variance/mean^2)
            
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

