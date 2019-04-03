classdef Zipf < DiscreteDistrib
    % A Zipf-like popularity distribution
    %
    % Copyright (c) 2018-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = Zipf(s, n)
            % Construct a Zipf-like distribution on n items with given
            % shape parameter s
            if ~exist('n','var')
                n = Distrib.Inf;
            end
            self@DiscreteDistrib('Zipf',4,[1,n]);
            p = 1./((1:n).^s)/Zipf.genHarmonic(s,n);
            x = 1:n;
            setParam(self, 1, 'p', p(:)', 'java.lang.Double');
            setParam(self, 2, 'x', x(:)', 'java.lang.Double');
            setParam(self, 3, 's', s, 'java.lang.Double');
            setParam(self, 4, 'n', n, 'java.lang.Integer');
            self.javaClass = '';
            self.javaParClass = '';
        end
        
        function ex = getMean(self)
            % Get distribution mean
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            ex = self.genHarmonic(s-1,n) / self.genHarmonic(s,n);
        end
        
        function SCV = getSCV(self)
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            ex = self.getMean();
            var = self.genHarmonic(s-2,n) / self.genHarmonic(s,n) - ex^2;
            SCV = var / ex^2;
        end
        
        function X = sample(self, n)
            % Get n samples from the distribution
            X = self.getParam(3).paramValue * ones(n,1);
        end
        
        function Ft = evalCDF(self,k)
            % Evaluate the cumulative distribution function at t
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            Ft = self.genHarmonic(s,k) / self.genHarmonic(s,n);
        end
        
        function p = evalPMF(self, k)
            % Evaluate the probability mass function at k
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            if ~exist('k','var')
                k = 1:n;
            end
            Hns = Zipf.genHarmonic(s,n);
            p = 1./(k.^s)/Hns;
        end
    end
    
    methods (Static)
        function Hnm = genHarmonic(s,n)
            % Generate harmonic numbers to normalize a Zipf-like distribution
            % on n items with shape parameter s
            Hnm = 0;
            for k=1:n
                Hnm = Hnm + 1/k^s;
            end
        end
    end
    
end

