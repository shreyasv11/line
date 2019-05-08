% getAG : export model in agent representation
function genAG(self)
% GENAG()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

% We now generate the global state space
% parses all but the service processes
M = self.getNumberOfStations();
K = self.getNumberOfClasses();
NK = self.getNumberOfJobs(); NK = NK(:);
classnames = self.getClassNames();
stationnames = self.getStationNames();
S = self.getStationServers();
sched = self.getStationScheduling();
refstat = self.getReferenceStations();
N = sum(NK(isfinite(NK)));
classprio = zeros(1,K);
schedparam = zeros(M,K);
for r=1:K
    classprio(r) = self.classes{r}.priority;
end

type = zeros(self.getNumberOfStations,1);
for i=1:self.getNumberOfStations
    switch class(self.nodes{i})
        case 'Queue'
            type(i) = NodeType.Queue;
            for k=(length(self.nodes{i}.server.serviceProcess)+1):K
                self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled()};
            end
        case 'DelayStation'
            type(i) = NodeType.Delay;
            for k=(length(self.nodes{i}.server.serviceProcess)+1):K
                self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled()};
            end
            %                    case 'Sink'
            %                    type(i) = NodeType.Sink;
        case 'Source'
            type(i) = NodeType.Source;
            for k=(length(self.nodes{i}.input.sourceClasses)+1):K
                self.nodes{i}.input.sourceClasses{k} = {[],ServiceStrategy.LI,Disabled()};
            end
    end
end

for i=1:M
    for r=1:K
        if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
            if isempty(self.stations{i}.server.serviceProcess{r})
                self.stations{i}.server.serviceProcess{r} = {[],ServiceStrategy.LI,Disabled()};
            end
        end
    end
end

for i=1:M
    for r=1:K
        if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
            if isempty(self.stations{i}.server.serviceProcess{r}) || self.stations{i}.server.serviceProcess{r}{end}.isDisabled || self.stations{i}.server.serviceProcess{r}{end}.isImmediate
                rates(i,r) = NaN;
            else
                rates(i,r) = 1/self.stations{i}.server.serviceProcess{r}{end}.getMean();
            end
        else
            if isempty(self.stations{i}.input.sourceClasses{r}) || self.stations{i}.input.sourceClasses{r}{end}.isDisabled || self.stations{i}.input.sourceClasses{r}{end}.isImmediate
                rates(i,r) = NaN;
            else
                rates(i,r) = 1/self.stations{i}.input.sourceClasses{r}{end}.getMean();
            end
        end
    end
    
    if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
        if ~isempty(self.stations{i}.schedStrategyPar)
            schedparam(i,:)=self.stations{i}.schedStrategyPar;
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

qn = NetworkStruct(M, K, N, S, rates, sched, rt, NK, eye(K), refstat,nodenames, stationnames, classnames);
% set zero bufffers for classes that are disabled
for i=1:qn.nstations
    for r=1:qn.nclasses
        c = find(qn.chains(:,r)); % chain of class r
        if isempty(qn.rates(i,r)) || qn.rates(i,r)==0 || any(~isfinite(qn.rates(i,r)))
            qn.classcap(i,r) = 0;
        else
            qn.classcap(i,r) = sum(qn.njobs(find(qn.chains(c,:))));
        end
    end
    qn.cap(i,1) = sum(qn.classcap(i,:));
end
qn.schedparam = schedparam;
[~,~,qn.classprio] = unique(classprio); qn.classprio = qn.classprio';

M = qn.nstations;
R = qn.nclasses;
N = qn.njobs';
rt = qn.rt;

% Then we analyse the queue in isolation with *constant* arrival
% rate equal to the average arrival rate
for i=1:qn.nnodes
    isf = qn.nodeToStateful(i);
    qn.space{isf} = State.fromMarginalBounds(qn, i, [], qn.classcap(i,:));
    if isinf(qn.nservers(i))
        qn.nservers(i) = sum(N);
    end
end

%%
active = 1; % column of active actions
passive = 2; % columns of passive actions
eps = M+1; % row of local actions
sync = {};
actionTable=[];
for i=1:M
    for r=1:R
        if length(qn.ph{i,r})>1
            sync{end+1} = struct('active',cell(1),'passive',cell(1));
            sync{end}.active{1} = struct('node',NaN,'class',NaN,'event',NaN);
            sync{end}.passive{1} = struct('node',NaN,'class',NaN,'event',NaN);
            sync{end}.active{1}.('node') = i;
            sync{end}.passive{1}.('node') = eps;
            sync{end}.active{1}.('class') = r;
            sync{end}.active{1}.('event') = EventType.PHASE;
            sync{end}.passive{1}.('class') = r;
            sync{end}.passive{1}.('event') = [];
            sync{end}.passive{1}.('prob') = 1; % probability to sync
        end
        %L(end+1,:) = [i, r, eps, r, EventType.PHASE, 0 ];
        for j=1:M
            for s=1:R
                state_prob = rt((i-1)*R+r,(j-1)*R+s);
                if state_prob > 0
                    sync{end+1} = struct('active',cell(1),'passive',cell(1));
                    sync{end}.active{1} = struct('node',NaN,'class',NaN,'event',NaN);
                    sync{end}.passive{1} = struct('node',NaN,'class',NaN,'event',NaN);
                    sync{end}.active{1}.('node') = i;
                    sync{end}.passive{1}.('node') = j;
                    sync{end}.active{1}.('class') = r;
                    sync{end}.active{1}.('event') = EventType.DEP;
                    sync{end}.passive{1}.('class') = s;
                    sync{end}.passive{1}.('event') = EventType.ARV;
                    sync{end}.passive{1}.('prob') = state_prob; % probability to sync
                    actionTable(end+1,:) = [i, r, j, s, EventType.DEP, EventType.ARV];
                end
            end
        end
    end
end
actionTable = unique(actionTable,'rows');
%%
SSh=[];
Q = sparse([]);
A = length(sync);
AP = []; % AP(a,1)= id of active agent for action a, AP(a,passive) = passive for action a
RL = cell(size(actionTable,1)+1,M); % RL{a,1}(s1,s2) rate from state s1 to s2 for action a in active agent, RL{a,2}(s1p,s2p) accept probability of passive
for j=1:M
    jsf = qn.stationToStateful(j);
    RL{end,j}=zeros(size(qn.space{jsf},1));
end
for a=1:A
    node_a = sync{a}.active{1}.node;
    class_a = sync{a}.active{1}.class;
    event_a = sync{a}.active{1}.event;
    
    node_p = sync{a}.passive{1}.node;
    class_p = sync{a}.passive{1}.class;
    event_p = sync{a}.passive{1}.event; if isempty(event_p), event_p=0; end
    prob_p = sync{a}.passive{1}.prob;
    
    if node_p ~= eps
        if prob_p > 0
            l = matchrow(actionTable,[node_a, class_a, node_p, class_p, event_a, event_p]);
            AP(l,active) = node_a; % active
            AP(l,passive) = node_p;
            RL{l,active} = zeros(size(qn.space{node_a},1));
            RL{l,passive} = zeros(size(qn.space{node_p},1));
            for s=1:size(SSh,1)
                state = SSh(s,:);
                state_a = state(node_a);
                [new_state_a, rate_a] = stateAfterEventHashed( qn, node_a, state_a, event_a,class_a);
                if new_state_a>0
                    RL{l,active}(state_a,new_state_a)=rate_a;
                    
                    node_p = sync{a}.passive{1}.node;
                    state_p = state(node_p);
                    if node_p == node_a %self-loop
                        [new_state_p, ~] = stateAfterEventHashed( qn, node_p, new_state_a, event_p, class_p);
                    else
                        [new_state_p, ~] = stateAfterEventHashed( qn, node_p, state_p, event_p, class_p);
                    end
                    RL{l,passive}(state_p,new_state_p)=prob_p;
                end
            end
        end
    else % local transitions
        for s=1:size(SSh,1)
            state = SSh(s,:);
            state_a = state(node_a);
            [new_state_a, rate_a] = stateAfterEventHashed(qn, node_a, state_a, event_a, class_a);
            if new_state_a > 0
                RL{end,node_a}(state_a,new_state_a)=RL{end,node_a}(state_a,new_state_a)+rate_a;
            end
        end
    end
end
todelete = [];
for l=1:size(RL,1)-1 % don't delete local events row
    if ~any(RL{l,1}(:))
        todelete = [todelete l];
    end
end
RL(todelete,:)=[];
AP(todelete,:)=[];
self.ag = struct('rate',RL,'role',AP);
end
