classdef Immediate < Distrib
    % A distribution with probability mass entirely at zero
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        %Constructor
        function self = Immediate()
            % SELF = IMMEDIATE()
            
            self@Distrib('Immediate', 0,[0,0]);
        end
    end
    
    methods
        function bool = isDisabled(self)
            % BOOL = ISDISABLED()
            
            bool = false;
        end
        
        function X = sample(self, n)
            % X = SAMPLE(N)
            
            if ~exist('n','var'), n = 1; end
            X = zeros(n,1);
        end
        
        function ex = getMean(self)
            % EX = GETMEAN()
            
            % Get distribution mean
            ex = 0;
        end
        
        function SCV = getSCV(self)
            % SCV = GETSCV()
            
            % Get distribution squared coefficient of variation (SCV = variance / mean^2)
            
            
            SCV = 0;
        end
        
        function Ft = evalCDF(self,t)
            % FT = EVALCDF(SELF,T)
            
            % Evaluate the cumulative distribution function at t
            % AT T
            
            Ft = 1;
        end
    end
    
end

