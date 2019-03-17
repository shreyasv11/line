function refreshStruct(self)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
self.sanitize();
nodetypes = self.getNodeTypes();
classnames = self.getClassNames();
nodenames = self.getNodeNames();
jobs = self.getNumberOfJobs();
servers = self.getStationServers();
refstat = self.getReferenceStations();
routing = self.getRoutingStrategies();
self.qn = NetworkStruct(nodetypes, nodenames, classnames, servers, jobs(:), refstat, routing);
self.refreshService();
self.refreshScheduling(self.qn.rates);
wantVisits = true;
if any(nodetypes == NodeType.Cache)
    wantVisits = false;
end
self.refreshChains(self.qn.rates, wantVisits);
self.refreshCapacity();
self.refreshPriorities();
self.refreshLocalVars();
self.refreshSync(); % this assumes that refreshChain is called before
%self.qn.forks = self.getForks(self.qn.rt);
end