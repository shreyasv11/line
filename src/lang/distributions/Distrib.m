classdef Distrib < Copyable
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    properties
        name
        params
        javaClass
        javaParClass
        support; % support interval
    end
    
    properties (Constant)
        Tol = 1e-3;
        InfTime = 1e10;
        InfRate = 1e10;
        InfItems = 1e10;
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function X = sample(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function ex = getMean(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function SCV = getSCV(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function Ft = evalCDF(self,t)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods (Hidden)
        %Constructor
        function self = Distrib(name, numParam, support)
            self.name = name;
            self.params = cell(1,numParam);
            self.support = support;
            for i=1:numParam
                self.params{i}=struct('paramName','','paramValue',NaN,'paramClass','');
            end
        end
        
        function bool = isContinuous(self)
            bool = any(~isfinite(self.support));
        end
        
        function bool = isDiscrete(self)
            bool = all(isfinite(self.support));
        end
        
        function self = setContinuous(self, iscontinuous)
            self.continuous = iscontinuous;
        end
        
        function nParam = getNumParams(self)
            nParam = length(self.params);
        end
        
        function setParam(self, id, name, value,typeClass)
            self.params{id}.paramName=name;
            self.params{id}.paramValue=value;
            self.params{id}.paramClass=typeClass;
        end
        
        function bool = isDisabled(self)
            bool = any(cellfun(@(c) isnan(c.paramValue), self.params));
        end
        
        function bool = isImmediate(self)
            bool = self.getMean() == 0;
        end
        
        function param = getParam(self,id)
            param = self.params{id};
        end
        
        function bool = isPhaseType(self)
            bool = isa(self,'PhaseType');
        end
    end
    
    methods
        function delta = evalCDFInterval(self,t0,t1)
            if t1>=t0
                Ft1 = self.evalCDF(t1);
                Ft0 = self.evalCDF(t0);
                delta = Ft1 - Ft0;
            else
                error('CDF interval incorrectly specified (t1<t0)');
            end
        end
    end
end