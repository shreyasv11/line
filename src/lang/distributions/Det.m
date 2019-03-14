classdef Det < Distrib
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods
        %Constructor
        function self = Det(t)
            self = self@Distrib('Det',1,[t,t]);
            setParam(self, 1, 't', t, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.DeterministicDistr';
            self.javaParClass = 'jmt.engine.random.DeterministicDistrPar';
        end
        
        function ex = getMean(self)
            ex = self.getParam(1).paramValue;
        end
        
        function SCV = getSCV(self)
            SCV = 0;
        end
        
        function X = sample(self, n)
            X = self.getParam(1).paramValue * ones(n,1);
        end
        
        function Ft = evalCDF(self,t)
            if t < self.getParam(1).paramValue
                Ft = 0;
            else
                Ft = 1;
            end
        end
    end
    
end

