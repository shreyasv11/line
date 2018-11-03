% U(i,r): mean utilization of class r at node i
function [U] = getAvgUtilHandles(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

% The method returns the handles to the performance indices but
% they are optional to collect
if isempty(self.handles) || ~isfield(self.handles,'U')
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    
    U = cell(M,1); % utilizations
    for i=1:M
        for r=1:K
            U{i,r} = PerfIndex(Perf.Util, self.classes{r}, self.stations{i});
            self.addPerfIndex(U{i,r});
            if isa(self.stations{i},'Source')
                U{i,r}.disable();
            end
            if isa(self.stations{i},'Sink')
                U{i,r}.disable();
            end
            if isa(self.stations{i},'JoinStation') || isa(self.stations{i},'ForkStation')
                U{i,r}.disable();
            end
            if ~strcmpi(class(self.stations{i}.server),'ServiceTunnel')
                if isempty(self.stations{i}.server.serviceProcess{r}) || strcmpi(class(self.stations{i}.server.serviceProcess{r}{end}),'Disabled')
                    U{i,r}.disable();
                end
            end
        end
    end
    self.handles.U = U;
else
    U = self.handles.U;
end
end