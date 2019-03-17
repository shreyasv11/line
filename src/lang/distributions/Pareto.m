classdef Pareto < ContinuousDistrib
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    methods
        %Constructor
        function self = Pareto(shape, scale)
            self = self@ContinuousDistrib('Pareto',2,[0,Inf]);
            if shape < 2
                error('shape parameter must be >= 2.0');
            end
            setParam(self, 1, 'alpha', shape, 'java.lang.Double');
            setParam(self, 2, 'k', scale, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Pareto';
            self.javaParClass = 'jmt.engine.random.ParetoPar';
        end
        
        function ex = getMean(self)
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            ex = shape * scale / (shape - 1);
        end
        
        function SCV = getSCV(self)
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            VAR = scale^2 * shape / (shape - 1)^2 / (shape - 2);
            ex = shape * scale / (shape - 1);
            SCV = VAR / ex^2;
        end
        
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            k = 1/shape;
            sigma = scale * k;
            X = gprnd(k, sigma, sigma/k, n, 1);
        end
        
        function Ft = evalCDF(self,t)
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            k = 1/shape;
            sigma = scale * k;
            Ft = gpcdf(t, k, sigma, sigma/k);
        end
    end
    
    methods (Static)        
        function pa = fitMeanAndSCV(MEAN, SCV)
            shape = (SCV*MEAN + MEAN*(SCV*(SCV + 1))^(1/2))/(SCV*MEAN);
            scale = MEAN + SCV*MEAN - MEAN*(SCV*(SCV + 1))^(1/2);
            pa = Pareto(shape,scale);
        end
    end
    
end
