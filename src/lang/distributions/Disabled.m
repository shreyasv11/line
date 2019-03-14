classdef Disabled < Distrib
    % Copyright (c) 2018-Present, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = Disabled()
            self@Distrib('Disabled', 1,[NaN,NaN]);
            setParam(self, 1, 'value', NaN, 'java.lang.Double');
        end
    end
    
    methods
        function bool = isContinuous(self)
            bool = true;
        end
        
        function bool = isDiscrete(self)
            bool = true;
        end
        
        function X = sample(self)
            X = NaN;
        end
        function ex = getMean(self)
            ex = NaN;
        end
        function SCV = getSCV(self)
            SCV = NaN;
        end
        function Ft = evalCDF(self,t)
            Ft = NaN;
        end
        
        function p = getPmf(self, k)
            p = 0*k;
        end
    end
    
end

