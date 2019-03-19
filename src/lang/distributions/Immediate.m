classdef Immediate < Distrib
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = Immediate()
            self@Distrib('Immediate', 0,[0,0]);
        end
    end
    
    methods        
        function bool = isDisabled(self)
            bool = false;
        end
        
        function X = sample(self)
            X = 0;
        end
        
        function ex = getMean(self)
            ex = 0;
        end
        
        function SCV = getSCV(self)
            SCV = 0;
        end
        
        function Ft = evalCDF(self,t)
            Ft = 1;
        end
    end
    
end

