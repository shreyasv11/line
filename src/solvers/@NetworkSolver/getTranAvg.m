function [QNclass_t, UNclass_t, TNclass_t] = getTranAvg(self,Qt,Ut,Tt)
% [QNCLASS_T, UNCLASS_T, TNCLASS_T] = GETTRANAVG(SELF,QT,UT,TT)

% Return transient average station metrics
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

if nargin == 1
    [Qt,Ut,Tt] = self.model.getTranHandles;
end
if nargin == 2
    handlers = Qt;
    Qt=handlers{1};
    Ut=handlers{2};
    %Rt=handlers{3};
    Tt=handlers{3};
end

QNclass_t={};
UNclass_t={};
%RNclass_t={};
TNclass_t={};

qn = self.model.getStruct;
minrate = min(qn.rates(isfinite(qn.rates)));
%if isempty(self.result) || isa(self.result.Avg.Q,double) || (isfield(self.options,'force') && self.options.force)
if ~self.hasTranResults()
    if isinf(self.options.timespan(1)) && isinf(self.options.timespan(2))
        self.options.timespan = [0,30/minrate];
        warning('Timespan of transient analysis unspecified, setting the timespan option to [0, %d]. Use %s(model,''timespan'',[0,T]) to customize.',self.options.timespan(2),class(self));
    end
    if isinf(self.options.timespan(1))
        warning('Start time of transient analysis unspecified, setting the timespan option to [0,%d].',self.options.timespan(2));
        self.options.timespan(1) = 0;
        %error('Please specify the transient range using the timespan option, e.g., SolverCTMC(model,''timespan'',[0,T]).getTranAvg()');
    end
    if isinf(self.options.timespan(2))
        self.options.timespan(2) = 30/minrate;
        warning('End time of transient analysis unspecified, setting the timespan option to [%d,%d]. Use %s(model,''timespan'',[0,T]) to customize.',self.options.timespan(1),self.options.timespan(2),class(self));
        %error('Please specify the transient range using the timespan option, e.g., SolverCTMC(model,''timespan'',[0,T]).getTranAvg()');
    end
    self.run();
end
%    if isempty(self.result)
%        return
%    end
%end

M = self.model.getNumberOfStations();
K = self.model.getNumberOfClasses();
if ~isempty(Qt)
    QNclass_t = cell(M,K);
    UNclass_t = cell(M,K);
    %RNclass_t = cell(M,K);
    TNclass_t = cell(M,K);
    for k=1:K
        for i=1:M
            ret = Qt{i,k}.get(self.result,self.model);
            metricVal = struct();
            metricVal.handle = {self.model.stations{i}, self.model.classes{k}};
            metricVal.t = ret(:,2);
            metricVal.metric = ret(:,1);
            metricVal.isaggregate = true;
            QNclass_t{i,k} = metricVal;            
            
            ret = Ut{i,k}.get(self.result,self.model);
            metricVal = struct();
            metricVal.handle = {self.model.stations{i}, self.model.classes{k}};
            metricVal.t = ret(:,2);
            metricVal.metric = ret(:,1);
            metricVal.isaggregate = true;
            UNclass_t{i,k} = metricVal;
            
            ret = Tt{i,k}.get(self.result,self.model);
            metricVal = struct();
            metricVal.handle = {self.model.stations{i}, self.model.classes{k}};
            metricVal.t = ret(:,2);
            metricVal.metric = ret(:,1);
            metricVal.isaggregate = true;
            TNclass_t{i,k} = metricVal;
        end
    end
end
end
