function self = refreshEnsemble(self, deepUpdate)
% SELF = REFRESSHENSEMBLE(ISBUILD, DEEPUPDATE)

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
ensemble = self.ensemble;
[lqnGraph, taskGraph] = self.getGraph();
%if isempty(myLQN.param.Nodes.RespT)
self.nodeMult = lqnGraph.Nodes.Mult(:);
self.edgeWeight = lqnGraph.Edges.Weight(:);
%end

if isempty(self.layerGraph)
    self.layerGraph = self.getGraphLayers();
end
graphLayer = self.layerGraph;

if isempty(self.clientTask)
    for net=1:length(graphLayer)
        self.clientTask{net} = unique(graphLayer{net}.Edges.EndNodes(:,1)');
    end
end
clientTask = self.clientTask;

myLQN = self;

% this script is valid only for loose layering
for net=1:length(graphLayer)
    jobclass = ensemble{net}.classes;
    qn = ensemble{net}.getStruct();
    
    %% define stations
    % create surrogate delay node for the layer
    serverName = myLQN.serverName{net};
    serverIndex = myLQN.getNodeIndex(serverName);
    
    %% define routing matrix
    for s = 1:length(clientTask{net}) % for all clients
        entries = myLQN.listEntriesOfTask(clientTask{net}{s});
        taskobj = myLQN.getNodeObject(clientTask{net}{s});
        isRefTask = strcmpi(taskobj.scheduling,SchedStrategy.REF);
        isProcessorInSubmodel = strcmpi(myLQN.getNodeProcessor(clientTask{net}{s}), serverName);
        for e=1:length(entries) % for all entries in the client task
            activities = myLQN.listActivitiesOfEntry(entries{e});
            entryobj = myLQN.getNodeObject(entries{e});
            %% setup think time for this entry
            classEntryName = entries{e};
            class_entry = cellfun(@(c) strcmpi(c.name,classEntryName),jobclass);
            
            if isRefTask
                interArrivalFromUpperLayer = 0; % no upper layer
            else % if this is not a ref task
                eidx = myLQN.getNodeIndex(classEntryName);
                tname = myLQN.getNodeTask(eidx);
                tidx = myLQN.getNodeIndex(tname);
                utilUpperLayerEntry = myLQN.param.Nodes.Util(eidx);
                tputUpperLayerEntry = myLQN.param.Nodes.Tput(eidx);
                if utilUpperLayerEntry > 1 % infinite server
                    if utilUpperLayerEntry < 1 + 1e-7
                        utilUpperLayerEntry = 1;
                    else
                        utilUpperLayerEntry = 1;
                        warning('Invalid utilization of the upper layer. Setting value to 1.0.');
                    end
                end
                if tputUpperLayerEntry == 0
                    interArrivalFromUpperLayer = Distrib.InfTime;
                else
                    interArrivalFromUpperLayer = jobclass{class_entry}.population*(1-utilUpperLayerEntry) / tputUpperLayerEntry;
                end
            end
            
            thinkTimeMean = taskobj.thinkTimeMean;
            thinkTimeSCV = taskobj.thinkTimeSCV;
            destEntryRate = min(Distrib.InfRate,1/(thinkTimeMean + interArrivalFromUpperLayer));
            if thinkTimeMean <= Distrib.Zero
                destEntryProcess = Exp(destEntryRate);
                [cx,demandMu,demandPhi] = Coxian.fitMeanAndSCV(1/destEntryRate, 1.0);
            elseif interArrivalFromUpperLayer <= Distrib.Zero
                destEntryProcess = taskobj.thinkTime;
                [cx,demandMu,demandPhi] = Coxian.fitMeanAndSCV(thinkTimeMean, thinkTimeSCV);
            end
            if deepUpdate
                ensemble{net}.nodes{1}.setService(jobclass{class_entry}, destEntryProcess);
            end
            
            classlast = class_entry;
            stationlast = 1;
            
            for a=1:length(activities) % for all activities in this entry
                %% determine properties of this activity
                actobj = myLQN.getNodeObject(activities{a});
                isBoundToEntry = strcmpi(actobj.boundToEntry, entryobj.name);
                
                %% first setup the host-demand of this activity
                % TODO: spread host-demand in-between calls
                className = activities{a};
                class_hostdemand = cellfun(@(c) strcmpi(c.name,className),jobclass);
                
                if isProcessorInSubmodel
                    % if host is the server in this submodel
                    % consume hostdemand at the server
                    if deepUpdate
                        ensemble{net}.nodes{2}.setService(jobclass{class_hostdemand}, actobj.hostDemand);
                    end
                else
                    % if the processor of this client is in another submodel
                    % spend time in the delay equivalent to response time
                    % of this activity
                    destEntryW = myLQN.param.Nodes.RespT(myLQN.getNodeIndex(activities{a}));
                    destEntryRate = 1/destEntryW;
                    entryRT = Exp(destEntryRate);
                    if deepUpdate
                        ensemble{net}.nodes{1}.setService(jobclass{class_hostdemand}, entryRT);
                    end
                end
                
                %% check if this is the last activity in the entry
                successors = lqnGraph.successors(myLQN.getNodeIndex(activities{a}))';
                isReplyActivity = true;
                if ~isempty(successors) % if the activity has successors
                    % check if the successors are remote entries, if not
                    % it's a leaf
                    for actnext = successors
                        if ~strcmpi(myLQN.getNodeType(actnext),'E') % skip successors that are remote entry calls
                            isReplyActivity = false;
                        end
                    end
                end
                
                selfLoopProb = 0;
                %% setup the synchronous calls
                for d=1:length(actobj.synchCallDests)
                    % first return to the delay in the appropriate class
                    destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.synchCallDests{d})};
                    if myLQN.edgeWeight(myLQN.findEdgeIndex(activities{a},destEntry)) >= 1
                        skipProb = 0;
                    else % call-mean < 1
                        skipProb = 1-myLQN.edgeWeight(myLQN.findEdgeIndex(activities{a},destEntry));
                    end
                    className = [activities{a},'=>',destEntry];
                    
                    class_synchcall = cellfun(@(c) strcmpi(c.name,className),jobclass);
                    
                    % now check if the dest entry's task is server in this submodel
                    isDestTaskInSubmodel = strcmpi(serverName,myLQN.getNodeTask(destEntry));
                    
                    if isDestTaskInSubmodel
                        % set service time at server for this entry
                        destEntryW = (1-skipProb)*myLQN.param.Nodes.RespT(myLQN.getNodeIndex(destEntry)); % this has to add the contribution of the other W not in this model
                        destEntryRate = 1/destEntryW;
                        entryRT = Exp(destEntryRate);
                        if deepUpdate
                            ensemble{net}.nodes{2}.setService(jobclass{class_synchcall}, entryRT);
                        end
                    else
                        if isProcessorInSubmodel % if host of source is in the model
                            % set as the service time, the response time of this call
                            edgeidx = myLQN.findEdgeIndex(activities{a},destEntry);
                            destEntryIdx = myLQN.getNodeIndex(destEntry);
                            destEntryW = (1-skipProb)*myLQN.param.Edges.RespT(edgeidx);
                            %destEntryW = (1-skipProb)*myLQN.param.Nodes.RespT(destEntryIdx);
                            destEntryRate = 1/destEntryW;
                            destEntryObj = Exp(destEntryRate);
                            if deepUpdate
                                ensemble{net}.nodes{1}.setService(jobclass{class_synchcall}, destEntryObj);
                            end
                            stationlast = 1;
                            classlast = class_synchcall;
                        else
                            % otherEdgesToSameEntry = findstring(G.Edges.EndNodes(:,1),activities{a});
                            % otherEdgesToSameEntry = setdiff(otherEdgesToSameEntry, myLQN.findEdgeIndex(activities{a},destEntryName)); % remove current
                            % destEntryW = destEntryW + sum(G.Edges.RespT(otherEdgesToSameEntry) .* G.Edges.Weight(otherEdgesToSameEntry));
                            edgeidx = myLQN.findEdgeIndex(activities{a},destEntry);
                            destEntryIdx = myLQN.getNodeIndex(destEntry);
                            destEntryW = (1-skipProb)*myLQN.param.Edges.RespT(edgeidx);
                            %destEntryW = (1-skipProb)*myLQN.param.Nodes.RespT(destEntryIdx);
                            destEntryRate = 1/destEntryW;
                            entryRT = Exp(destEntryRate);
                            % set think time at clients for this entry
                            if deepUpdate
                                ensemble{net}.nodes{1}.setService(jobclass{class_synchcall}, entryRT);
                            end
                        end
                    end
                end
                
                %% setup the asynchronous calls
                for d=1:length(actobj.asynchCallDests)
                    % first return to the delay in the appropriate class
                    destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.asynchCallDests{d})};
                    className = [activities{a},'->',destEntry];
                    class_asynchcall = cellfun(@(c) strcmpi(c.name,className),jobclass);
                    destEntryRate = 1/myLQN.param.Edges.RespT(myLQN.findEdgeIndex(activities{a},destEntry));
                    % ... to finish
                end
                
                %% handle case this is a reply (leaf node) in the activity graph
                
                if isReplyActivity
                    % loop back to entry
                else
                    for actnext = successors
                        if ~strcmpi(myLQN.getNodeType(actnext),'E') % skip successors that are remote entry calls
                            act_name = myLQN.getNodeName(actnext);
                            classnext = cellfun(@(c) strcmpi(c.name,act_name), jobclass);
                            edge_a_as = myLQN.findEdgeIndex(myLQN.getNodeIndex(activities{a}),actnext);
                            if isProcessorInSubmodel
                                stationlast = 2;
                                classlast = classnext;
                            else
                                stationlast = 1;
                                classlast = classnext;
                            end
                        end
                    end
                end
            end
        end
    end
    ensemble{net}.reset();
end

myLQN.setGraph(lqnGraph, taskGraph);
myLQN.setEnsemble(ensemble);
return
end


%qn.rates(1,jobclass{class_synchcall}) = destEntryObj.getRate;
%qn.mu{1,jobclass{class_synchcall}} = destEntryObj.getMu;
%qn.phi{1,jobclass{class_synchcall}} = destEntryObj.getPhi;
%qn.proc{1,jobclass{class_synchcall}} = destEntryObj.getRepresentation;
%qn.phases(1,jobclass{class_synchcall}) = length(%qn.phases(1,jobclass{class_synchcall}));
