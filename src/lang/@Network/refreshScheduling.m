function [sched, schedid, schedparam] = refreshScheduling(self, rates)
% [SCHED, SCHEDID, SCHEDPARAM] = REFRESHSCHEDULING(SELF, RATES)
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

% determine scheduling parameters
M = self.getNumberOfStations();
K = self.getNumberOfClasses();

sched = self.getStationScheduling();
schedparam = zeros(M,K);
for i=1:M
    if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
        switch self.stations{i}.server.className
            case 'ServiceTunnel'
                % do nothing
            otherwise
                if ~isempty(self.stations{i}.schedStrategyPar) & ~isnan(self.stations{i}.schedStrategyPar) %#ok<AND2>
                    schedparam(i,:) = self.stations{i}.schedStrategyPar;
                else
                    switch sched{i}
                        case SchedStrategy.SEPT
                            [~,~,rnk] = unique(1./rates(i,:));
                            schedparam(i,:)=rnk';
                        case SchedStrategy.LEPT
                            [~,~,rnk] = unique(rates(i,:));
                            schedparam(i,:)=rnk';
                    end
                end
        end
    end
end

if ~isempty(self.qn)
    self.qn.setSched(sched, schedparam);
end
end
