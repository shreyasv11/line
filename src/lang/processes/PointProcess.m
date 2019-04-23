classdef PointProcess < Copyable
    % An abstract class for stochastic point processes
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        name
        params
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function X = sample(self)
            % X = SAMPLE(SELF)
            
            % Sample a value from the inter-arrival time distribution
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function ex = getMean(self)
            % EX = GETMEAN(SELF)
            
            % Returns the mean of the inter-arrival times
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function SCV = getSCV(self)
            % SCV = GETSCV(SELF)
            
            % Get squared coefficient of variation of the interarrival times (SCV = variance / mean^2)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function SKEW = getSkewness(self)
            % SKEW = GETSKEWNESS(SELF)
            
            % Get skewness of the interarrival times
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function ID = getID(self)
            % ID = GETID(SELF)
            
            % Return the asymptotic index of dispersion
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function lambda = getRate(self)
            % LAMBDA = GETRATE(SELF)
            
            % Return the inter-arrival rate
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function vart = evalVarT(self,t)
            % VART = EVALVART(SELF,T)
            
            % Evaluate the variance-time curve at t
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods (Hidden)
        %Constructor
        function self = PointProcess(name, numParam)
            % SELF = POINTPROCESS(NAME, NUMPARAM)
            
            self.name = name;
            self.params = cell(1,numParam);
            for i=1:numParam
                self.params{i}=struct('paramName','','paramValue',-1,'paramClass','');
            end
        end
        
        function nParam = getNumParams(self)
            % NPARAM = GETNUMPARAMS(SELF)
            
            nParam = length(self.params);
        end
        
        function setParam(self, id, name, value,typeClass)
            % SETPARAM(SELF, ID, NAME, VALUE,TYPECLASS)
            
            self.params{id}.paramName=name;
            self.params{id}.paramValue=value;
            self.params{id}.paramClass=typeClass;
        end
        
        function bool = isDisabled(self)
            % BOOL = ISDISABLED(SELF)
            
            bool = any(cellfun(@(c) ifthenelse(isstruct(c),false,isnan(c.paramValue)), self.params));
        end
        
        function bool = isImmediate(self)
            % BOOL = ISIMMEDIATE(SELF)
            
            bool = self.getMean() == 0;
        end
        
        function param = getParam(self,id)
            % PARAM = GETPARAM(SELF,ID)
            
            param = self.params{id};
        end
    end
    
end
