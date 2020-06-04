function self = updateParam(self, AvgTableLayer)
% SELF = UPDATEPARAM(AVGTABLELAYER)
%
% Update the LQN parameterization based on the solutions of each layer in
% isolation.
%
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
%if isempty(self.chains)
for net = netorder
    % list of activity classes and their type
    self.syncCall{net} = containsstr(AvgTableLayer{net}.Class,'=>');
    self.asyncCall{net} = containsstr(AvgTableLayer{net}.Class,'->');
    self.isCall{net} = (self.syncCall{net} | self.asyncCall{net});
    self.syncSource{net} = extractBefore(AvgTableLayer{net}.Class,'=>');
    self.asyncSource{net} = extractBefore(AvgTableLayer{net}.Class,'->');
    self.syncDest{net} = extractAfter(AvgTableLayer{net}.Class,'=>');
    self.asyncDest{net} = extractAfter(AvgTableLayer{net}.Class,'->');
    self.chains{net} = network{net}.getChains();
    self.serverName{net} = network{net}.stations{2}.name;
end
%end

for net = netorder
    % then update all values of the non-call activities
    for h=find(startsWith(AvgTableLayer{net}.Class,'A'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTableLayer{net}.RespT(h)) % if not disabled
            if ~self.isCall{net}(h) % if neither sync-call nor async-call
                aname = AvgTableLayer{net}.Class{h};
                aidx = self.getNodeIndex(aname);
                ename = self.getNodeEntry(aidx);
                eidx = self.getNodeIndex(ename);
                pname = self.getNodeProcessor(eidx);
                pidx = self.getNodeIndex(pname);
                tname = self.getNodeTask(eidx);
                tidx = self.getNodeIndex(tname);
                %entry_chainidx = find(cellfun(@(c) any(strcmpi(c.classnames, ename)), self.chains{net}));
                if strcmpi(pname, self.serverName{net}) % if server is this activity's processor
                    param.Nodes.Tput(aidx) = AvgTableLayer{net}.Tput(h);
                    param.Nodes.RespT(aidx) = AvgTableLayer{net}.RespT(h);
                    param.Nodes.RespT(eidx) = param.Nodes.RespT(eidx) + param.Nodes.RespT(aidx);  % needs some notion of visit?
                end
            end
        end
    end
end

for net = netorder
    % first update all values for the entries
    for h=find(startsWith(AvgTableLayer{net}.Class,'E'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTableLayer{net}.RespT(h)) % if not disabled
            ename = AvgTableLayer{net}.Class{h};
            eidx = self.getNodeIndex(ename);
            pname = self.getNodeProcessor(eidx);
            tname = self.getNodeTask(eidx);
            tidx = self.getNodeIndex(tname);
            if strcmpi(pname, self.serverName{net}) % if server is this entry's processor
                if find(refTasks == tidx) % if entry is part of ref task
                    param.Nodes.Tput(eidx) = AvgTableLayer{net}.Tput(h);
                end
            end
        end
    end
end

for net = netorder
    % then update all values of the call activities
    rt = network{net}.getRoutingMatrix;
    for h=find(startsWith(AvgTableLayer{net}.Class,'A'))'% 1:length(WT{net}.Station) % for all param
        if ~isnan(AvgTableLayer{net}.RespT(h)) % if not disabled
            if self.syncCall{net}(h)
                edgeidx = self.findEdgeIndex(self.syncSource{net}{h}, self.syncDest{net}{h});
                asourcename = self.syncSource{net}{h};
                asourceidx = self.getNodeIndex(asourcename);
                esourcename = self.getNodeEntry(asourceidx);
                esourceidx = self.getNodeIndex(esourcename);
                tsourcename = self.getNodeTask(asourceidx);
                %tsourceidx = self.getNodeIndex(tsourcename);
                etargetname = self.syncDest{net}{h};
                etargetidx = self.getNodeIndex(etargetname);
                ttargetname = self.getNodeTask(etargetidx);
                %ttargetidx = self.getNodeIndex(ttargetname);
                if strcmpi(ttargetname, self.serverName{net}) % if server is this activity's task
                    entry_chainidx = cellfun(@(c) any(strcmpi(c.classnames, AvgTableLayer{net}.Class(h))), self.chains{net});
                    %% mandatory metrics
                    if  strcmp(self.ensemble{net}.getStruct.sched{2},'inf')  % if server is an infinite server
                        nJobs = network{net}.getNumberOfJobs;
                        net_chains = network{net}.getChains(rt);
                        inChain = net_chains{entry_chainidx}.index{:};
                        chainPopulation = sum(nJobs(inChain));
                        param.Nodes.Util(etargetidx) = param.Nodes.Util(etargetidx) + AvgTableLayer{net}.Util(h) / chainPopulation;
                    else % for multi-server nodes LINE already returns utilizations between 0-1
                        param.Nodes.Util(etargetidx) = param.Nodes.Util(etargetidx) + AvgTableLayer{net}.Util(h);
                    end
                    if self.edgeWeight(edgeidx)>=1
                        param.Nodes.Tput(etargetidx) = param.Nodes.Tput(etargetidx) + AvgTableLayer{net}.Tput(h);
                        param.Nodes.RespT(esourceidx) = param.Nodes.RespT(esourceidx) + self.param.Edges.RespT(edgeidx)*self.edgeWeight(edgeidx);
                    else
                        param.Nodes.Tput(etargetidx) = param.Nodes.Tput(etargetidx) + AvgTableLayer{net}.Tput(h)*self.edgeWeight(edgeidx);
                        param.Nodes.RespT(esourceidx) = param.Nodes.RespT(esourceidx) + self.param.Edges.RespT(edgeidx);
                    end
                    param.Edges.RespT(edgeidx) = AvgTableLayer{net}.RespT(h); % so that contributions from other calls are included
                end
            elseif self.asyncCall{net}(h)
                % aname = self.asyncSource{net}{h};
                % edgeidx = self.findEdgeIndex(self.asyncSource{net}{h}, self.asyncDest{net}{h});
                % G.Edges.RespT(edgeidx) = G.Edges.RespT(edgeidx) + RT{net}.Value(h);
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
% - self.param.Nodes.RespT(eidx) = for entries, includes response at processor layer + response time of calls
% - self.param.Nodes.RespT(aidx) = for activities, excludes response time of calls
% - self.param.Edges.RespT(edge) = time for an activity to call the entry once
% - self.param.Nodes.Util = entry utilization used by buildlqn, not the processor util
