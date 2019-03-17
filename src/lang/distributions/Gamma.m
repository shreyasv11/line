classdef Gamma < ContinuousDistrib
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Gamma(shape, scale)
            self = self@ContinuousDistrib('Gamma',2,[0,Inf]);
            setParam(self, 1, 'alpha', shape, 'java.lang.Double');
            setParam(self, 2, 'beta', scale, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.GammaDistr';
            self.javaParClass = 'jmt.engine.random.GammaDistrPar';
        end
                
        function ex = getMean(self)
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            ex = shape*scale;
        end
        
        function SCV = getSCV(self)
            shape = self.getParam(1).paramValue;
            SCV = 1 / shape;
        end
        
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            X = gamrnd(shape, scale, n, 1);
        end        
        
        function Ft = evalCDF(self,t)
            shape = self.getParam(1).paramValue;
            scale = self.getParam(2).paramValue;
            Ft = gamcdf(t,shape,scale);
        end
    end

    methods(Static)
        
        function gm = fitMeanAndSCV(MEAN, SCV)
            shape = 1 / SCV;
            scale = MEAN / shape;
            gm = Gamma(shape, scale);
        end
        
    end
    
end

