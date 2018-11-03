classdef PointProcess < matlab.mixin.Copyable
    % Copyright (c) 2018, Imperial College London
    % All rights reserved.
    
    properties
        name
        params
        javaClass
        javaParClass
    end
    
    methods(Abstract)
%        X = sample(self); % inter-arrival time
        ex = getMean(self); % inter-arrival time
        SCV = getSCV(self); % inter-arrival time
%        ID = getID(self); % asymptotic index of dispersion
%        lambda = getRate(self);
%        vart = getVarT(self,t);
    end
        
    methods (Hidden)
        %Constructor
        function self = PointProcess(name, numParam)
            self.name = name;
            self.params = cell(1,numParam);
            for i=1:numParam
                self.params{i}=struct('paramName','','paramValue',-1,'paramClass','');
            end
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
            bool = any(cellfun(@(c) ifthenelse(isstruct(c),false,isnan(c.paramValue)), self.params));
        end
        
        function bool = isImmediate(self)
            bool = self.getMean() == 0;
        end
        
        function param = getParam(self,id)
            param = self.params{id};
        end
        
        function bool = isPhaseType(self)
            bool = isa(self,'MarkovModulated');
        end
    end
    
end