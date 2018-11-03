classdef Uniform < Distrib
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Uniform(minVal, maxVal)
            self = self@Distrib('Uniform',2,[minVal,maxVal]);
            setParam(self, 1, 'min', minVal, 'java.lang.Double');
            setParam(self, 2, 'max', maxVal, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Uniform';
            self.javaParClass = 'jmt.engine.random.UniformPar';
        end
        
        function ex = getMean(self)
            ex = (self.getParam(2).paramValue+self.getParam(1).paramValue) / 2;
        end
        
        function SCV = getSCV(self)
            var = (self.getParam(2).paramValue-self.getParam(1).paramValue)^2 / 12;
            SCV = var/self.getMean()^2;
        end
        
        function Ft = evalCDF(self,t)
            minVal = self.getParam(1).paramValue;
            maxVal = self.getParam(2).paramValue;
            if t < minVal
                Ft = 0;
            elseif t > maxVal
                Ft = 0;
            else
                Ft = 1/(maxVal-minVal);
            end
        end
    end
    
end

