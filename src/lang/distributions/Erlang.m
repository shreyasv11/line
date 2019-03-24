classdef Erlang < PhaseType
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Erlang(alpha, r)
            self = self@PhaseType('Erlang',2);
            setParam(self, 1, 'alpha', alpha, 'java.lang.Double'); % rate in each state
            setParam(self, 2, 'r', round(r), 'java.lang.Long'); % number of phases
            self.javaClass = 'jmt.engine.random.Erlang';
            self.javaParClass = 'jmt.engine.random.ErlangPar';
        end
        
        function phases = getNumberOfPhases(self)
            phases  = self.getParam(2).paramValue; %r
        end
        
        function bool = isImmmediate(self)
            bool = self.getMean() == 0;
        end
        
        function ex = getMean(self)
            alpha = self.getParam(1).paramValue;
            r = self.getParam(2).paramValue;
            ex = r/alpha;
        end
        
        function SCV = getSCV(self)
            r = self.getParam(2).paramValue;
            SCV = 1/r;
        end
                
        function Ft = evalCDF(self,t)
            alpha = self.getParam(1).paramValue; % rate
            r = self.getParam(2).paramValue; % stages
            Ft = 1;
            for j=0:(r-1)
                Ft = Ft - exp(-r*alpha*t).*(r*alpha*t).^j/factorial(j);
            end
        end
        
        function PH = getRenewalProcess(self)
            r = self.getParam(2).paramValue;
            PH = map_erlang(self.getMean(),r);
        end
        
%        function L = getLaplaceTransform(self, s)
%            alpha = self.getParam(1).paramValue; % rate
%            r = self.getParam(2).paramValue; % stages
%            L = (alpha / (alpha + s))^r;
%        end
        
    end
    
    methods(Static)
        function er = fit(MEAN,SCV)
            er = Erlang.fitMeanAndSCV(MEAN,SCV);
        end
        
        function er = fitMeanAndSCV(MEAN, SCV)
            r = ceil(1/SCV);
            alpha = r/MEAN;
            er = Erlang(alpha, r);
        end
        
        function er = fitMeanAndOrder(MEAN, n)
            SCV = 1/n;
            r = ceil(1/SCV);
            alpha = r/MEAN;
            er = Erlang(alpha, r);
        end
        
    end
    
end

