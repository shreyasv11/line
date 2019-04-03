function self = updateEnsemble(self, isBuild, deepUpdate)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
ensemble = self.ensemble;
[lqnGraph, taskGraph] = self.getGraph();
%if isempty(self.param.Nodes.RespT)
self.nodeMult = lqnGraph.Nodes.Mult(:);
self.edgeWeight = lqnGraph.Edges.Weight(:);
%end

if isempty(self.layerGraph)
    [self.layerGraph, ~] = self.getGraphLayers(lqnGraph, taskGraph);
end
graphLayer = self.layerGraph;
%graphs are returned with updated Multiplicity fields on the 'inf' tasks
maxJobs = Distrib.Inf; % maximum number of jobs allowed in a submodel class.
if isempty(self.clientTask)
    for net=1:length(graphLayer)
        self.clientTask{net} = unique(graphLayer{net}.Edges.EndNodes(:,1)');
    end
end
clientTask = self.clientTask;

% this script is valid only for loose layering
for net=1:length(graphLayer)
    if isBuild
        ensemble{net} = Network(sprintf('Submodel_%d',net));
        node = {};
        jobclass = {};
        myP = {};
    else
        node{1} = ensemble{net}.nodes{1};
        node{2} = ensemble{net}.nodes{2};
        jobclass = ensemble{net}.classes;
        qn = ensemble{net}.getStruct();
    end
    
    %% define stations
    % create surrogate delay node for the layer
    if isBuild
        node{1} = DelayStation(ensemble{net}, 'Clients');
    end
    % create a queueing station for the single target in the lower layer
    if isBuild
        serverName = graphLayer{net}.Edges.EndNodes{1,2};
    else
        serverName = self.serverName{net};
    end
    serverIndex = self.getNodeIndex(serverName);
    if isBuild
        obj = self.getNodeObject(serverName);
        switch obj.scheduling
            case 'inf'
                node{2} = DelayStation(ensemble{net}, serverName);
            otherwise
                node{2} = Queue(ensemble{net}, serverName, obj.scheduling);
                node{2}.setNumServers(self.nodeMult(serverIndex));
        end
    end
    
    %% define classes
    if isBuild
        myP{1,1} = zeros(length(node)); % initialize routing matrix - don't move
    end
    
    if isBuild
        for s = 1:length(clientTask{net}) % for all client activities
            entries = self.listEntriesOfTask(clientTask{net}{s});
            taskobj = self.getNodeObject(clientTask{net}{s});
            if strcmpi(taskobj.scheduling,'ref')
                isRefTask = true;
                isRefTaskPopulationLoaded = false;
            else
                isRefTask = false;
            end
            isDestTask = false;
            if graphLayer{net}.Edges.EndNodes{s,2}(1) == 'T'
                isDestTask = true; % otherwise is a processor
            end
            for e=1:length(entries) % for all entries in the client
                activities = self.listActivitiesOfEntry(entries{e});
                entryobj = self.getNodeObject(entries{e});
                % add a new class for this entry's think time
                myP = initclass(myP,length(node),length(jobclass));
                className = entries{e};
                jobclass{end+1} = ClosedClass(ensemble{net}, className, 0, node{1}, 0);
                jobclass{end}.completes = false;
                if isRefTask
                    % if client is a reference task set the clients
                    if ~isRefTaskPopulationLoaded % load population in first entry of the ref task
                        jobclass{end}.population = taskobj.multiplicity;
                        isRefTaskPopulationLoaded = true;
                    end
                else
                    % else this is a non-reference task
                    if isinf(taskobj.multiplicity) % if the client task uses the inf policy
                        taskName = clientTask{net}{s};
                        predecessors = taskGraph.predecessors(taskName);
                        predecJobs = 0; % number of jobs that can call the task
                        for p=1:length(predecessors)
                            predecJobs = predecJobs + self.nodeMult(self.getNodeIndex(predecessors{p}));
                        end
                        if isinf(predecJobs)
                            predecJobs = maxJobs;
                            self.nodeMult(self.getNodeIndex(clientTask{net}{s})) = Inf; % problem if set to maxJobs, but worth retrying
                            %taskGraph.Nodes.Mult(self.getNodeIndexInTaskGraph(clientTask{net}{s})) = Inf;
                        else
                            self.nodeMult(self.getNodeIndex(clientTask{net}{s})) = predecJobs;
                            %taskGraph.Nodes.Mult(self.getNodeIndexInTaskGraph(clientTask{net}{s})) = predecJobs;
                        end
                        jobclass{end}.population = predecJobs;
                    else % else use the number of servers
                        jobclass{end}.population = taskobj.multiplicity;
                    end
                end
                
                isEntryCallingDestTask = false;
                for a=1:length(activities) % for all activities in the entry
                    actobj = self.getNodeObject(activities{a});
                    
                    % add a new class for this activity
                    myP = initclass(myP,length(node),length(jobclass));
                    className = activities{a};
                    jobclass{end+1} = ClosedClass(ensemble{net}, className, 0, node{1}, 0);
                    jobclass{end}.completes = false;
                    
                    % add artificial classes for synch-calls
                    for d=1:length(actobj.synchCallDests)
                        myP = initclass(myP,length(node),length(jobclass));
                        nJobs = 0;
                        destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.synchCallDests{d})};
                        className = [activities{a},'=>',destEntry];
                        if isDestTask
                            isEntryCallingDestTask = true;
                        end
                        jobclass{end+1} = ClosedClass(ensemble{net}, className, nJobs, node{1}, 0);
                        jobclass{end}.completes = false;
                    end
                    
                    % add artificial classes for asynch-calls
                    for d=1:length(actobj.asynchCallDests)
                        myP = initclass(myP,length(node),length(jobclass));
                        nJobs = 0;
                        
                        destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.asynchCallDests{d})};
                        className = [activities{a},'->',destEntry];
                        if isDestTask
                            isEntryCallingDestTask = true;
                        end
                        
                        jobclass{end+1} = ClosedClass(ensemble{net}, className, nJobs, node{1}, 0);
                        jobclass{end}.completes = false;
                    end
                    %                    if isDestTask && ~isEntryCallingDestTask
                    %                        jobclass{entryJobClass}.population = 0;
                    %                    end
                end
            end
        end
    end
    
    %% define routing matrix
    for s = 1:length(clientTask{net}) % for all clients
        entries = self.listEntriesOfTask(clientTask{net}{s});
        taskobj = self.getNodeObject(clientTask{net}{s});
        isRefTask = strcmpi(taskobj.scheduling,'ref');
        for e=1:length(entries) % for all entries in the client task
            activities = self.listActivitiesOfEntry(entries{e});
            entryobj = self.getNodeObject(entries{e});
            %% setup think time for this entry
            classEntryName = entries{e};
            class_entry = cellfun(@(c) strcmpi(c.name,classEntryName),jobclass);
            
            if isRefTask
                interArrivalFromUpperLayer = 0; % no upper layer
            else % if this is not a ref task
                eidx = self.getNodeIndex(classEntryName);
                tname = self.getNodeTask(eidx);
                tidx = self.getNodeIndex(tname);
                utilUpperLayerEntry = self.param.Nodes.Util(eidx);
                tputUpperLayerEntry = self.param.Nodes.Tput(eidx);
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
            isProcessorInSubmodel = strcmpi(self.getNodeProcessor(entries{e}), serverName);
            
            thinkTime = taskobj.thinkTimeMean; if isnan(thinkTime), thinkTime = 0; end
            destEntryRate = min(Distrib.InfRate,1/(thinkTime + interArrivalFromUpperLayer));
            if thinkTime == 0
                destEntryProcess = Exp(destEntryRate);
                if ~isBuild
                    demandMu = destEntryRate;
                    demandPhi = 1.0;
                end
            elseif interArrivalFromUpperLayer == 0
                destEntryProcess = taskobj.thinkTime;
                if isempty(destEntryProcess)
                    destEntryProcess = Exp(Distrib.InfRate);
                end
                if ~isBuild
                    [demandMu,demandPhi] = Coxian.fitMeanAndSCV(taskobj.thinkTimeMean, taskobj.thinkTimeSCV);
                end                
            else % convolution of thinkTime and interArrivalFromUpperLayer processes
% The code will never enter this section since thinkTime is available only
% in the reference task that has no arrivals from an upper layer
%                 thinkTimeMAP = taskobj.thinkTime.getRepresentation();
%                 D0 = [thinkTimeMAP{1},sum(thinkTimeMAP{2},2);zeros(1,size(thinkTimeMAP{1},2)),-interArrivalFromUpperLayer];
%                 D1 = zeros(size(D0)); D1(end,1:end-1) = interArrivalFromUpperLayer*map_pie(thinkTimeMAP);
%                 destEntryMAP = {D0,D1};
%                 destEntryMean = map_mean(destEntryMAP);
%                 destEntrySCV = map_scv(destEntryMAP);
%                 destEntryProcess = Cox2.fitMeanAndSCV(destEntryMean,destEntrySCV);
%                 if destEntryMean == 0
%                     destEntryProcess = Exp(Distrib.InfRate);
%                     destEntrySCV = 1;
%                     demandMu = Distrib.InfRate;
%                     demandPhi = 1.0;
%                 elseif ~isBuild
%                     [demandMu,demandPhi] = Coxian.fitMeanAndSCV(destEntryMean, destEntrySCV);
%                 end
            end
            if isBuild
                node{1}.setService(jobclass{class_entry}, destEntryProcess);
                node{2}.setService(jobclass{class_entry}, Disabled());
            else
                qn.rates(1,jobclass{class_entry}.index) = destEntryRate;
                qn.mu{1,jobclass{class_entry}.index} = demandMu;
                qn.phi{1,jobclass{class_entry}.index} = demandPhi;
                if deepUpdate
                    node{1}.setService(jobclass{class_entry},  destEntryProcess);
                end
            end
            classlast = class_entry;
            stationlast = 1;
            
            for a=1:length(activities) % for all activities in this entry
                %% determine properties of this activity
                actobj = self.getNodeObject(activities{a});
                isBoundToEntry = strcmpi(actobj.boundToEntry, entryobj.name);
                
                %% first setup the host-demand of this activity
                % TODO: spread host-demand in-between calls
                className = activities{a};
                class_hostdemand = cellfun(@(c) strcmpi(c.name,className),jobclass);
                
                if isProcessorInSubmodel
                    % if host is the server in this submodel
                    % consume hostdemand at the server
                    if isBuild
                        if isBoundToEntry
                            if isRefTask
                                myP{classlast, class_hostdemand}(stationlast,2) = 1/length(entries); % visit first the activity bound to entry
                                for h=setdiff(1:length(entries),e) % for all other entries in the client ref task
                                    classhEntryName = entries{h};
                                    classh_entry = cellfun(@(c) strcmpi(c.name,classhEntryName),jobclass);
                                    myP{classlast, classh_entry}(stationlast,stationlast) = 1/length(entries); % visit first the activity bound to entry
                                end
                            else
                                myP{classlast, class_hostdemand}(stationlast,2) = 1; % visit first the activity bound to entry
                            end
                        end
                        demandRate = 1/actobj.hostDemandMean;
                        if isnan(demandRate), demandRate = Distrib.InfRate; end
                        if isBuild
                            node{1}.setService(jobclass{class_hostdemand}, Disabled());
                            %node{2}.setService(jobclass{class_hostdemand}, Exp(demandRate));
                            node{2}.setService(jobclass{class_hostdemand}, actobj.hostDemand);
                        else
                            if deepUpdate
                                %node{2}.setService(jobclass{class_hostdemand}, Exp(demandRate));
                                node{2}.setService(jobclass{class_hostdemand}, actobj.hostDemand);
                            end
                            qn.rates(2,jobclass{class_hostdemand}.index) = destEntryRate;
                            [demandMu,demandPhi] = Coxian.fitMeanAndSCV(actobj.hostDemandMean, actobj.hostDemandSCV);
                            qn.mu{2,jobclass{class_hostdemand}.index} = demandMu;
                            qn.phi{2,jobclass{class_hostdemand}.index} = demandPhi;
                        end
                        stationlast = 2; % store that we last visited the server
                        classlast = class_hostdemand; % store class for return path
                    end
                else
                    % if the processor of this client is in another submodel
                    % spend time in the delay equivalent to response time
                    % of this activity
                    if isBoundToEntry
                        myP{classlast, class_hostdemand}(stationlast,1) = 1; % visit first the activity bound to entry
                    end
                    destEntryW = self.param.Nodes.RespT(self.getNodeIndex(activities{a}));
                    destEntryRate = 1/destEntryW;
                    entryRT = Exp(destEntryRate);
                    if isBuild
                        node{1}.setService(jobclass{class_hostdemand}, entryRT);
                    else
                        if deepUpdate
                            node{1}.setService(jobclass{class_hostdemand}, entryRT);
                        end
                        qn.rates(1,jobclass{class_hostdemand}.index) = destEntryRate;
                        qn.mu{1,jobclass{class_hostdemand}.index} = destEntryRate;
                    end
                    if isBuild % if we are building the model for the first time
                        node{2}.setService(jobclass{class_hostdemand}, Disabled());
                        stationlast = 1; % store that we last visited the server
                        classlast = class_hostdemand; % store class for return path
                    end
                end
                
                %% check if this is the last activity in the entry
                successors = lqnGraph.successors(self.getNodeIndex(activities{a}))';
                isReplyActivity = true;
                if ~isempty(successors) % if the activity has successors
                    % check if the successors are remote entries, if not
                    % it's a leaf
                    for actnext = successors
                        if ~strcmpi(self.getNodeType(actnext),'E') % skip successors that are remote entry calls
                            isReplyActivity = false;
                        end
                    end
                end
                
                selfLoopProb = 0; skipProb = 0;
                %% setup the synchronous calls
                for d=1:length(actobj.synchCallDests)
                    % first return to the delay in the appropriate class
                    destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.synchCallDests{d})};
                    if self.edgeWeight(self.findEdgeIndex(activities{a},destEntry)) >= 1
                        skipProb = 0;
                    else % call-mean < 1
                        skipProb = 1-self.edgeWeight(self.findEdgeIndex(activities{a},destEntry));
                    end
                    className = [activities{a},'=>',destEntry];
                    
                    class_synchcall = cellfun(@(c) strcmpi(c.name,className),jobclass);
                    
                    % now check if the dest entry's task is server in this submodel
                    isDestTaskInSubmodel = strcmpi(serverName,self.getNodeTask(destEntry));
                    
                    if isDestTaskInSubmodel
                        % set service time at server for this entry
                        if isBuild % if we are building the model for the first time
                            node{1}.setService(jobclass{class_synchcall}, Disabled());
                        end
                        destEntryW = (1-skipProb)*self.param.Nodes.RespT(self.getNodeIndex(destEntry)); % this has to add the contribution of the other W not in this model
                        destEntryRate = 1/destEntryW;
                        entryRT = Exp(destEntryRate);
                        if isBuild
                            node{2}.setService(jobclass{class_synchcall}, entryRT);
                        else
                            if deepUpdate
                                node{2}.setService(jobclass{class_synchcall}, entryRT);
                            end
                            qn.rates(2,jobclass{class_synchcall}.index) = destEntryRate;
                            qn.mu{2,jobclass{class_synchcall}.index} = destEntryRate;
                        end
                        if isBuild % if we are building the model for the first time
                            % Here we are taking the assumption that if the
                            % destination is FCFS and there are two calls in a row
                            % to the same destination then the second call queues
                            % again
                            myP{classlast, classlast}(stationlast,stationlast)=selfLoopProb;
                            myP{classlast, class_synchcall}(stationlast,2)=1-selfLoopProb;
                            stationlast = 2;
                            classlast = class_synchcall;
                        end
                    else
                        if isProcessorInSubmodel % if host of source is in the model
                            % set as the service time, the response time of this call
                            if isBuild
                                entryRT = Exp(Distrib.InfRate); % sync-call A=>B has no intrinsic demand at its processor
                                node{2}.setService(jobclass{class_synchcall}, entryRT);
                            end
                            myP{classlast, classlast}(stationlast,stationlast)=selfLoopProb;
                            myP{classlast, class_synchcall}(stationlast,1)=1-selfLoopProb;
                            edgeidx = self.findEdgeIndex(activities{a},destEntry);
                            destEntryIdx = self.getNodeIndex(destEntry);
                            destEntryW = (1-skipProb)*self.param.Edges.RespT(edgeidx);
                            %destEntryW = (1-skipProb)*self.param.Nodes.RespT(destEntryIdx);
                            destEntryRate = 1/destEntryW;
                            if isBuild
                                node{1}.setService(jobclass{class_synchcall}, Exp(destEntryRate));
                            else
                                if deepUpdate
                                    node{1}.setService(jobclass{class_synchcall}, Exp(destEntryRate));
                                end
                                qn.rates(1,jobclass{class_synchcall}.index) = destEntryRate;
                                qn.mu{1,jobclass{class_synchcall}.index} = destEntryRate;
                            end
                            stationlast = 1;
                            classlast = class_synchcall;
                        else
                            %                             otherEdgesToSameEntry = findstring(G.Edges.EndNodes(:,1),activities{a});
                            %                             otherEdgesToSameEntry = setdiff(otherEdgesToSameEntry, self.findEdgeIndex(activities{a},destEntryName)); % remove current
                            %                             destEntryW = destEntryW + sum(G.Edges.RespT(otherEdgesToSameEntry) .* G.Edges.Weight(otherEdgesToSameEntry));
                            edgeidx = self.findEdgeIndex(activities{a},destEntry);
                            destEntryIdx = self.getNodeIndex(destEntry);
                            destEntryW = (1-skipProb)*self.param.Edges.RespT(edgeidx);
                            %destEntryW = (1-skipProb)*self.param.Nodes.RespT(destEntryIdx);
                            destEntryRate = 1/destEntryW;
                            entryRT = Exp(destEntryRate);
                            % set think time at clients for this entry
                            if isBuild
                                node{1}.setService(jobclass{class_synchcall}, entryRT);
                            else
                                if deepUpdate
                                    node{1}.setService(jobclass{class_synchcall}, entryRT);
                                end
                                qn.rates(1,jobclass{class_synchcall}.index) = destEntryRate;
                                qn.mu{1,jobclass{class_synchcall}.index} = destEntryRate;
                            end
                            if isBuild % if we are building the model for the first time
                                %                                node{2}.setService(jobclass{class_synchcall}, Disabled());
                                node{2}.setService(jobclass{class_synchcall}, Exp(Distrib.InfRate));
                                myP{classlast, classlast}(stationlast,stationlast)=selfLoopProb;
                                myP{classlast, class_synchcall}(stationlast,1)=1-selfLoopProb;
                                stationlast = 1;
                                classlast = class_synchcall;
                            end
                        end
                    end
                    if isBuild % if we are building the model for the first time
                        if self.edgeWeight(self.findEdgeIndex(activities{a},destEntry)) >= 1
                            selfLoopProb = 1-1/self.edgeWeight(self.findEdgeIndex(activities{a},destEntry));
                            %                        skipProb = 0;
                        else % call-mean < 1
                            selfLoopProb = 0;
                            %                        skipProb = 1-G.Edges.Weight(self.findEdgeIndex(activities{a},destEntryName));
                        end
                    end
                end
                
                %% setup the asynchronous calls
                for d=1:length(actobj.asynchCallDests)
                    % first return to the delay in the appropriate class
                    destEntry = lqnGraph.Nodes.Name{findstring(lqnGraph.Nodes.Node,actobj.asynchCallDests{d})};
                    className = [activities{a},'->',destEntry];
                    class_asynchcall = cellfun(@(c) strcmpi(c.name,className),jobclass);
                    destEntryRate = 1/self.param.Edges.RespT(self.findEdgeIndex(activities{a},destEntry));
                    % ... to finish
                end
                
                %% handle case this is a reply (leaf node) in the activity graph
                
                if isReplyActivity
                    % loop back to entry
                    if isBuild
                        myP{classlast,classlast}(stationlast,stationlast)=selfLoopProb;
                        myP{classlast,class_entry}(stationlast,1)=1-selfLoopProb;
                        jobclass{classlast}.completes = true;
                    end
                else
                    for actnext = successors
                        if ~strcmpi(self.getNodeType(actnext),'E') % skip successors that are remote entry calls
                            act_name = self.getNodeName(actnext);
                            classnext = cellfun(@(c) strcmpi(c.name,act_name), jobclass);
                            edge_a_as = self.findEdgeIndex(self.getNodeIndex(activities{a}),actnext);
                            if isProcessorInSubmodel
                                %                                myP{classlast,classlast}(stationlast, stationlast)= 1-1/G.Edges.Weight(edge_a_as);
                                %                                myP{classlast,classnext}(stationlast, 2)= 1/G.Edges.Weight(edge_a_as);
                                myP{classlast,classlast}(stationlast, stationlast)= selfLoopProb;
                                myP{classlast,classnext}(stationlast, 2)= 1-selfLoopProb;
                                stationlast = 2;
                                classlast = classnext;
                            else
                                %                                myP{classlast,classlast}(stationlast, stationlast)= 1-1/G.Edges.Weight(edge_a_as);
                                %                                myP{classlast,classnext}(stationlast, 1)= 1/G.Edges.Weight(edge_a_as);
                                myP{classlast,classlast}(stationlast, stationlast)= selfLoopProb;
                                myP{classlast,classnext}(stationlast, 1)= 1-selfLoopProb;
                                stationlast = 1;
                                classlast = classnext;
                            end
                        end
                    end
                end
            end
        end
    end
    if isBuild % if we are building the model for the first time
        ensemble{net}.link(myP);
    else
        ensemble{net}.qn = qn;
    end
end
self.setGraph(lqnGraph, taskGraph);
self.setEnsemble(ensemble);
return
end

function myP = initclass(myP,M,R)
P0 = zeros(M);
myP{R+1,R+1} = P0;
for c=1:R
    myP{c,R+1} = P0;
    myP{R+1,c} = P0;
end
end