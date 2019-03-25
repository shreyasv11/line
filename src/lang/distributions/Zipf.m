classdef Zipf < DiscreteDistrib
    % A Zipf-like popularity distribution
    %
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods
        %Constructor
        function self = Zipf(s, n)
            if ~exist('n','var')
                n = Distrib.InfItems;
            end
            self = self@DiscreteDistrib(1./((1:n).^s)/Zipf.genharmonic(n,s),1:n);
            setParam(self, 3, 's', s, 'java.lang.Double');
            setParam(self, 4, 'n', n, 'java.lang.Integer');
            self.javaClass = '';
            self.javaParClass = '';
        end
        
        function ex = getMean(self)
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            ex = self.genharmonic(n,s-1) / self.genharmonic(n,s);
        end
        
        function SCV = getSCV(self)
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            ex = self.getMean();
            var = self.genharmonic(n,s-2) / self.genharmonic(n,s) - ex^2;
            SCV = var / ex^2;
        end
        
        function X = sample(self, n)
            X = self.getParam(3).paramValue * ones(n,1);
        end
        
        function Ft = evalCDF(self,k)
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            Ft = self.genharmonic(k,s) / self.genharmonic(n,s); 
        end
        
        function p = getPmf(self, k)
            s = self.getParam(3).paramValue;
            n = self.getParam(4).paramValue;
            if ~exist('k','var')
                k = 1:n;
            end
            Hns = Zipf.genharmonic(n,s);
            p = 1./(k.^s)/Hns;
        end
    end
    
    methods (Static)
        function Hnm = genharmonic(n,m)
            Hnm = 0;
            for k=1:n
                Hnm = Hnm + 1/k^m;
            end
        end
    end
    
end

