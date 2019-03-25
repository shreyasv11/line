function [QNclass_t, UNclass_t, TNclass_t] = getTranAvg(self,Qt,Ut,Tt)
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

%if isempty(self.result) || isa(self.result.Avg.Q,double) || (isfield(self.options,'force') && self.options.force)
if ~self.hasTranResults()
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
            QNclass_t{i,k} = Qt{i,k}.get(self.result,self.model);
            UNclass_t{i,k} = Ut{i,k}.get(self.result,self.model);
            %                            RNclass_t{i,k} = R{i,k}.get(self.result,self.model);
            TNclass_t{i,k} = Tt{i,k}.get(self.result,self.model);
        end
    end
end
end
