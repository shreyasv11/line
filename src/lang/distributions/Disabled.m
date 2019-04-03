classdef Disabled < ContinuousDistrib & DiscreteDistrib
    % A distribution that is not configured
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = Disabled()
            % Constructs a disabled distribution
            self@ContinuousDistrib('Disabled',1,[NaN,NaN]);
            self@DiscreteDistrib('Disabled',1,[NaN,NaN]);
            setParam(self, 1, 'value', NaN, 'java.lang.Double');
        end
    end
    
    methods
        function bool = isContinuous(self)
            % Returns true is the distribution is continuous
            bool = true;
        end
        
        function bool = isDiscrete(self)
            % Returns true is the distribution is discrete
            bool = true;
        end
        
        function X = sample(self, n)
            % Get n samples from the distribution
            if ~exist('n','var'), n = 1; end
            X = nan(n,1);
        end
        
        function ex = getMean(self)
            % Get distribution mean
            ex = NaN;
        end
        
        function SCV = getSCV(self)
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            SCV = NaN;
        end
        
        function Ft = evalCDF(self,t)
            % Evaluate the cumulative distribution function at t
            Ft = NaN;
        end
        
        function p = evalPMF(self, k)
            % Evaluate the probability mass function at k
            p = 0*k;
        end
    end
    
end

