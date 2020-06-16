function lqn = getStruct(self)
% LQN = GETSTRUCT(SELF)
%
%
% Copyright 2012-2020, Imperial College London

lqn = struct();
lqn.nidx = 0;
lqn.nhosts = length(self.hosts);
lqn.ntasks = length(self.tasks);
lqn.nreftasks = length(self.reftasks);
lqn.nacts = length(self.activities);
lqn.nentries = length(self.entries);
lqn.ntasksof = [];
lqn.nentriesof = [];
lqn.nactsof = [];

for p=1:lqn.nhosts
    lqn.ntasksof(p) = length(self.hosts{p}.tasks);
end

%% analyze static properties
idx = 1;
lqn.hostidx = [];
lqn.taskidx = [];
lqn.entryidx = [];
lqn.actidx = [];
lqn.tasksof = cell(lqn.nhosts,1);
lqn.entriesof = cell(lqn.ntasks,1);
lqn.actsof = cell(lqn.ntasks,1);
lqn.callsof = cell(lqn.ntasks,1);
lqn.proc = {};
lqn.sched = {};
lqn.names = {};
lqn.shortnames = {};
lqn.mult = [];
lqn.nidx = lqn.nhosts + lqn.ntasks + lqn.nentries + lqn.nacts;
lqn.type = zeros(lqn.nidx,1);
lqn.graph = sparse([]);
lqn.replies = [];
lqn.replygraph = sparse([]);

tshift = lqn.nhosts;
eshift = lqn.nhosts + lqn.ntasks;
ashift = lqn.nhosts + lqn.ntasks + lqn.nentries;

lqn.parent = [];
for p=1:lqn.nhosts
    lqn.hostidx(end+1) = idx;
    lqn.sched{idx,1} = self.hosts{p}.scheduling;
    lqn.mult(idx,1) = self.hosts{p}.multiplicity;
    lqn.names{idx,1} = self.hosts{p}.name;
    lqn.shortnames{idx,1} = ['H',num2str(p)];
    lqn.type(idx) = LayeredNetworkElement.HOST; % processor
    idx = idx + 1;
end

for p=1:lqn.nhosts
    pidx = p;
    for t=1:lqn.ntasksof(p)
        lqn.taskidx(end+1) = idx;
        lqn.sched{idx,1} = self.hosts{p}.tasks(t).scheduling;
        lqn.proc{idx,1} = self.hosts{p}.tasks(t).thinkTime;
        lqn.mult(idx,1) = self.hosts{p}.tasks(t).multiplicity;
        lqn.names{idx,1} = self.hosts{p}.tasks(t).name;
        lqn.shortnames{idx,1} = ['T',num2str(idx-tshift)];
        lqn.parent(idx) = pidx;
        lqn.graph(idx, pidx) = 1;
        lqn.nentriesof(idx) = length(self.hosts{p}.tasks(t).entries);
        lqn.nactsof(idx) = length(self.hosts{p}.tasks(t).activities);
        lqn.type(idx) = LayeredNetworkElement.TASK; % task
        idx = idx + 1;
    end
    lqn.tasksof{pidx} = find(lqn.parent == pidx);
end

tasks = self.tasks;
for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    for e=1:lqn.nentriesof(tidx)
        lqn.entryidx(end+1) = idx;
        lqn.names{idx,1} = self.tasks{t}.entries(e).name;
        lqn.shortnames{idx,1} = ['E',num2str(idx-eshift)];
        lqn.proc{idx,1} = Immediate();
        lqn.parent(idx) = tidx;
        lqn.graph(tidx,idx) = 1;
        lqn.entriesof{tidx}(e) = idx;
        lqn.type(idx) = LayeredNetworkElement.ENTRY; % entries
        idx = idx + 1;
    end
end

for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    for a=1:lqn.nactsof(tidx)
        lqn.actidx(end+1) = idx;
        lqn.names{idx,1} = tasks{t}.activities(a).name;
        lqn.shortnames{idx,1} = ['AS',num2str(idx - ashift)];
        lqn.proc{idx,1} = tasks{t}.activities(a).hostDemand;
        lqn.parent(idx) = tidx;
        lqn.actsof{tidx}(a) = idx;
        lqn.type(idx) = LayeredNetworkElement.ACTIVITY; % activities
        idx = idx + 1;
    end
end

nidx = idx - 1; % number of indices
lqn.graph(nidx,nidx) = 0;

%% now analyze calls
cidx = 0;
lqn.callidx = sparse(lqn.nidx,lqn.nidx);
lqn.calltype = sparse([],lqn.nidx,1);
lqn.iscaller = sparse([],lqn.ntasks, lqn.nentries);
lqn.callpair = [];
lqn.callproc = {};
lqn.callnames = {};
lqn.callshortnames = {};
lqn.taskgraph = sparse([],lqn.ntasks, lqn.ntasks);
lqn.actpre = sparse(lqn.nidx,1);
lqn.actpost = sparse(lqn.nidx,1);

shift = lqn.nhosts + lqn.ntasks;
for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    lqn.actsof{tidx} = zeros(1,lqn.nactsof(tidx));
    for a=1:lqn.nactsof(tidx)
        aidx = findstring(lqn.names, tasks{t}.activities(a).name);
        lqn.callsof{aidx} = [];        
        lqn.actsof{tidx}(a) = aidx;
        lqn.proc{aidx,1} = tasks{t}.activities(a).hostDemand;
        
        boundToEntry = tasks{t}.activities(a).boundToEntry;
        %for b=1:length(boundToEntry)
            eidx = findstring(lqn.names, boundToEntry);
            if eidx>0
                lqn.graph(eidx, aidx) = 1;
            end
        %end
        
        for s=1:length(tasks{t}.activities(a).syncCallDests)
            target_eidx = findstring(lqn.names, tasks{t}.activities(a).syncCallDests{s});
            target_tidx = lqn.parent(target_eidx);
            cidx = cidx + 1;
            lqn.callidx(aidx, target_eidx) = cidx;
            lqn.calltype(cidx,1) = CallType.SYNC;
            lqn.callpair(cidx,1:2) = [aidx,target_eidx];
            lqn.callnames{cidx,1} = [lqn.names{aidx},'=>',lqn.names{target_eidx}];
            lqn.callshortnames{cidx,1} = [lqn.shortnames{aidx},'=>',lqn.shortnames{target_eidx}];
            lqn.callproc{cidx,1} = Geometric(1/tasks{t}.activities(a).syncCallMeans(s)); % synch
            lqn.callsof{aidx}(end+1) = cidx;
            lqn.iscaller(tidx, target_eidx) = true;
            lqn.taskgraph(tidx, target_tidx) = 1;
            lqn.graph(aidx, target_eidx) = 1;
        end
        for s=1:length(tasks{t}.activities(a).asyncCallDests)
            target_eidx = findstring(lqn.names,tasks{t}.activities(a).asyncCallDests{s});
            target_tidx = lqn.parent(target_eidx);
            cidx = cidx + 1;
            lqn.callidx(aidx, target_eidx) = cidx;
            lqn.callpair(cidx,1:2) = [aidx,target_eidx];
            lqn.calltype(cidx,1) = CallType.ASYNC; % async
            lqn.callnames{cidx,1} = [lqn.names{aidx},'->',lqn.names{target_eidx}];
            lqn.callshortnames{cidx,1} = [lqn.shortnames{aidx},'->',lqn.shortnames{target_eidx}];
            lqn.callproc{cidx,1} = Geometric(1/tasks{t}.activities(a).asyncCallDests(s)); % asynch
            lqn.callsof{aidx}(end+1) = cidx;
            lqn.iscaller(tidx, target_eidx) = true;
            lqn.taskgraph(tidx, target_tidx) = 1;
            lqn.graph(aidx, target_eidx) = 1;
        end
    end
    
    for ap=1:length(tasks{t}.precedences)
        preacts = tasks{t}.precedences(ap).preActs;
        postacts = tasks{t}.precedences(ap).postActs;
        for prea = 1:length(preacts)
            preaidx = findstring(lqn.names, tasks{t}.precedences(ap).preActs{prea});
            for posta = 1:length(postacts)
                postaidx = findstring(lqn.names, tasks{t}.precedences(ap).postActs{posta});
                lqn.graph(preaidx, postaidx) = 1;
                lqn.actpre(preaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).preType));
                lqn.actpost(preaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).postType));
            end
        end
    end
end

lqn.replies = false(1,lqn.nidx);
lqn.replygraph = 0*lqn.graph;
for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    for aidx = lqn.actsof{tidx}
        postaidxs = find(lqn.graph(aidx, :));
        isreply = true;
        % if no successor is an action of tidx
        for postaidx = postaidxs
            if any(lqn.actsof{tidx} == postaidx)
                isreply = false;
            end
        end
        if isreply
            % this is a leaf node, search backward for the parent entry,
            % which is assumed to be unique
            lqn.replies(aidx) = true;
            parentidx = aidx;
            while lqn.type(parentidx) ~= LayeredNetworkElement.ENTRY
                ancestors = find(lqn.graph(:,parentidx));
                parentidx = at(ancestors,1); % only choose first ancestor
            end
            if lqn.type(parentidx) == LayeredNetworkElement.ENTRY
                lqn.replygraph(aidx, parentidx) = 1;
            end
        end
    end
end

end