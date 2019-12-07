function self = updateParam(self, AvgTable)
% SELF = UPDATEPARAM(AVGTABLE)

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
network = self.getEnsemble();
[lqnGraph,taskGraph] = self.getGraph();

nNodes = length(self.nodeNames);
nEdges = size(self.endNodes,1);

param.Nodes.RespT = zeros(nNodes,1);
param.Nodes.Tput = zeros(nNodes,1);
param.Nodes.Util = zeros(nNodes,1);
param.Edges.RespT = zeros(nEdges,1);
param.Edges.Tput = zeros(nEdges,1);
updateNodeW = zeros(nNodes);

if isempty(self.param.Nodes.RespT)
    self.nodeMult = lqnGraph.Nodes.Mult(:);
    self.edgeWeight = lqnGraph.Edges.Weight(:);
end
persistent netorder;
if isempty(netorder) || length(netorder) ~= length(network)
    netorder = 1:length(network);
end
netorder = netorder(end:-1:1); %elevator

refTasks = findstring(lqnGraph.Nodes.Type, 'R');
if isempty(self.chains)
    for net = netorder
        % list of activity classes and their type
        self.syncCall{net} = containsstr(AvgTable{net}.Class,'=>');
        self.asyncCall{net} = containsstr(AvgTable{net}.Class,'->');
        self.isCall{net} = (self.syncCall{net} | self.asyncCall{net});
        self.syncSource{net} = extractBefore(AvgTable{net}.Class,'=>');
        self.asyncSource{net} = extractBefore(AvgTable{net}.Class,'->');
        self.syncDest{net} = extractAfter(AvgTable{net}.Class,'=>');
        self.asyncDest{net} = extractAfter(AvgTable{net}.Class,'->');
        self.chains{net} = network{net}.getChains();
        self.serverName{net} = network{net}.stations{2}.name;
    end
end

for net = netorder
    % then update all values of the non-call activities
    for h=find(startsWith(AvgTable{net}.Class,'A'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTable{net}.RespT(h)) % if not disabled
            if ~self.isCall{net}(h) % if neither sync-call nor async-call
                aname = AvgTable{net}.Class{h};
                aidx = self.getNodeIndex(aname);
                %ename = lqnGraph.Nodes.Entry{aidx};
                %eidx = self.getNodeIndex(ename);
                eidx = self.nodeDep(aidx,3);
                if isnan(eidx)
                    eidx = self.getNodeIndex(self.findEntryOfActivity(aname));
                    self.nodeDep(aidx,3) = eidx;
                end
                pname = self.getNodeProcessor(eidx);
                pidx = self.getNodeIndex(pname);
                tname = self.getNodeTask(eidx);
                tidx = self.getNodeIndex(tname);
                %entry_chainidx = find(cellfun(@(c) any(strcmpi(c.classnames, ename)), self.chains{net}));
                if strcmpi(pname, self.serverName{net}) % if server is this activity's processor
                    param.Nodes.Tput(aidx) = AvgTable{net}.Tput(h);
                    param.Nodes.RespT(aidx) = AvgTable{net}.RespT(h);
                    param.Nodes.RespT(eidx) = param.Nodes.RespT(eidx) + param.Nodes.RespT(aidx);  % needs some notion of visit?
                end
            end
        end
    end
end

for net = netorder
    % first update all values for the entries
    for h=find(startsWith(AvgTable{net}.Class,'E'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTable{net}.RespT(h)) % if not disabled
            ename = AvgTable{net}.Class{h};
            eidx = self.getNodeIndex(ename);
            pname = self.getNodeProcessor(eidx);
            tname = self.getNodeTask(eidx);
            tidx = self.getNodeIndex(tname);
            if strcmpi(pname, self.serverName{net}) % if server is this entry's processor
                if find(refTasks == tidx) % if entry is part of ref task
                    ename = AvgTable{net}.Class{h};
                    eidx = self.getNodeIndex(ename);
                    param.Nodes.Tput(eidx) = AvgTable{net}.Tput(h);
                end
            end
        end
    end
end

for net = netorder
    % then update all values of the call activities
    for h=find(startsWith(AvgTable{net}.Class,'A'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTable{net}.RespT(h)) % if not disabled
            if self.syncCall{net}(h)
                aname = self.syncSource{net}{h};
                aidx = self.getNodeIndex(aname);
                targetentryname = self.syncDest{net}{h};
                targetentryidx = self.getNodeIndex(targetentryname);
                edgeidx = self.findEdgeIndex(self.syncSource{net}{h}, self.syncDest{net}{h});
                % psourcename = getNodeProcessor(aname);
                % ptargetname = getNodeProcessor(targetentryidx);
                tsourcename = self.getNodeTask(self.syncSource{net}{h});
                tsourceidx = self.getNodeIndex( tsourcename);
                esourcename = lqnGraph.Nodes.Entry{aidx};
                esourceidx = self.getNodeIndex(esourcename);
                esourceidx = self.nodeDep(aidx,3);
                taskdestname = self.getNodeTask(targetentryidx);
                taskdestidx = self.getNodeIndex(taskdestname);
                if strcmpi(taskdestname, self.serverName{net}) % if server is this activity's task
                    entry_chainidx = cellfun(@(c) any(strcmpi(c.classnames, AvgTable{net}.Class(h))), self.chains{net});
                    %% mandatory metrics
                    if  strcmp(self.ensemble{net}.getStruct.sched{2},'inf')  % if server is an infinite server
                        nJobs = network{net}.getNumberOfJobs;
                        inChain = network{net}.getChains{entry_chainidx}.index{:};
                        chainPopulation = sum(nJobs(inChain));
                        param.Nodes.Util(targetentryidx) = param.Nodes.Util(targetentryidx) + AvgTable{net}.Util(h) / chainPopulation;
                    else % for multi-server nodes LINE already returns utilizations between 0-1
                        param.Nodes.Util(targetentryidx) = param.Nodes.Util(targetentryidx) + AvgTable{net}.Util(h);
                    end
                    if self.edgeWeight(edgeidx)>=1
                        param.Nodes.Tput(targetentryidx) = param.Nodes.Tput(targetentryidx) + AvgTable{net}.Tput(h);
                        param.Nodes.RespT(esourceidx) = param.Nodes.RespT(esourceidx) + self.edgeWeight(edgeidx)*self.param.Edges.RespT(edgeidx);
                    else
                        param.Nodes.Tput(targetentryidx) = param.Nodes.Tput(targetentryidx) + AvgTable{net}.Tput(h)*self.edgeWeight(edgeidx);
                        param.Nodes.RespT(esourceidx) = param.Nodes.RespT(esourceidx) + self.param.Edges.RespT(edgeidx);
                    end
                    param.Edges.RespT(edgeidx) = AvgTable{net}.RespT(h); % so that contributions from other calls are included
                end
            elseif self.asyncCall{net}(h)
                %                            aname = self.asyncSource{net}{h};
                %                            edgeidx = self.findEdgeIndex(self.asyncSource{net}{h}, self.asyncDest{net}{h});
                %                            G.Edges.RespT(edgeidx) = G.Edges.RespT(edgeidx) + RT{net}.Value(h);
            end
        end
    end
end
self.setGraph(lqnGraph, taskGraph);

self.param.Nodes.RespT = param.Nodes.RespT;
self.param.Nodes.Tput = param.Nodes.Tput;
self.param.Nodes.Util = param.Nodes.Util;

self.param.Edges.RespT = param.Edges.RespT;
self.param.Edges.Tput = param.Edges.Tput;
end

%% PERF INDEXES CONVENTION
% - nodes.RespT(eidx) = for entries, includes response at processor layer + response time of calls
% - nodes.RespT(aidx) = for activities, excludes response time of calls
% - edges.RespT(edge) = time for an activity to call the entry once
% - nodes.Util = entry utilization used by buildlqn, not the processor util
