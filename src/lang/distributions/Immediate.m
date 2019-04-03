classdef Immediate < Distrib
    % A distribution with probability mass entirely at zero
    %
    % Copyright (c) 2012-2019, Imperial College London
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
        
        function X = sample(self, n)
            if ~exist('n','var'), n = 1; end
            X = zeros(n,1);
        end
        
                function ex = getMean(self)
            % Get distribution mean
            ex = 0;
        end
        
                function SCV = getSCV(self)
% Get distribution squared coefficient of variation (SCV = variance / mean^2)


            SCV = 0;
        end
        
        function Ft = evalCDF(self,t)
% Evaluate the cumulative distribution function at t
            Ft = 1;
        end
    end
    
end

