classdef Exp < PhaseType
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = Exp(lambda)
            self = self@PhaseType('Exponential', 1);
            setParam(self, 1, 'lambda', lambda, 'java.lang.Double');
            self.javaClass = 'jmt.engine.random.Exponential';
            self.javaParClass = 'jmt.engine.random.ExponentialPar';
        end
        
        function phases = getNumberOfPhases(self)
            phases  = 1;
        end
        
        function ex = getMean(self)
            lambda = self.getParam(1).paramValue;
            ex = 1/lambda;
        end
        
        function SCV = getSCV(self)
            SCV = 1;
        end
        
        function phases = numberOfPhases(self)
            phases  = 1;
        end
        
        function Ft = evalCDF(self,t)
            lambda = self.getParam(1).paramValue;
            Ft = 1-exp(-lambda*t);
        end
        
        function PH = getRenewalProcess(self)
            PH = map_exponential(self.getMean());
        end
        
    end
    
    methods (Static)
        function ex = fitRate(RATE)
            ex = Exp(RATE);
        end
        
        function ex = fit(MEAN)
            ex = Exp.fitMeanAndSCV(MEAN,1.0);
        end
        
        function ex = fitMean(MEAN)
            ex = Exp.fit(MEAN);
        end
        
        function Qcell = fromMatrix(Lambda)
            Qcell = cell(size(Lambda));
            for i=1:size(Lambda,1)
                for j=1:size(Lambda,2)
                    Qcell{i,j} = Exp(Lambda(i,j));
                end
            end
        end
        function ex = fitMeanAndSCV(MEAN, SCV)
            if nargin==2
                if SCV ~= 1
                    fprintf(1,'Cannot fit SCV other than 1.0 with Exp.');
                end
            else
                SCV = 1;
            end
            ex = Exp(1/MEAN);
        end
    end
end

