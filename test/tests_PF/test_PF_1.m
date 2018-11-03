
% Getting started example from the LINE documentation
model = Network('mrDemo3');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'QueueRepairman1', SchedStrategy.PS);
station{3} = Queue(model, 'QueueRepairman2', SchedStrategy.PS);
station{4} = Queue(model, 'QueueRepairman3', SchedStrategy.PS);

N1 = 2; jobclass{1} = ClosedClass(model, 'MachinesA', N1, station{1});
N2 = 5; jobclass{2} = ClosedClass(model, 'MachinesB', N2, station{1});

rate = [1,1; 2,1; 2,2; 2,10];
for i=1:4
    for r=1:2
        station{i}.setService(jobclass{r}, Exp(rate(i,r)));
    end
end

P{1} = circul(4); % type-A
P{2} = circul(4); % type-B
model.link(P);
qn=model.getStruct();
%% generate local state spaces
space = {};
spacesz = [];

M = qn.nstations;
R = qn.nclasses;
N = qn.njobs;
P = qn.rt;

for i=1:M
    qn.space{i} = stateFromMarginalBounds(qn, i, [], qn.classcap(i,:));
    if isinf(qn.nservers(i))
        qn.nservers(i) = sum(N);
    end
    spacesz(i) = size(qn.space{i},1);
end
%%
J = stateClosedMultiCS(M,N',qn.chains);

for j=1:size(J,1)
    for i=1:M
        v = stateFromMarginal(qn,i,J(j,i:M:end));
        netstates{j,i} = stateHash(qn,i,v);
    end
end

%%
ctr = 0;
%SS = sparse([]);
SS = [];
SSh = [];
for j=1:size(J,1)
    % for each network state
    v = {netstates{j,:}};
    % cycle over lattice
    vN = cellfun(@length,v)-1;
    n = pprod(vN);
    while n >=0
        u={}; h={};
        skip = false;
        for i=1:length(n)
            h{i} = v{i}(1+n(i));
            if h{i} < 0
                skip = true;
                break
            end
            u{i} = qn.space{i}(v{i}(1+n(i)),:);
        end
        if skip == false
            ctr = ctr + 1; % do not move
            SS(ctr,:)=cell2mat(u);
            SSh(ctr,:)=cell2mat(h);
        end
        n = pprod(n,vN);
    end
end

%%
eps = M+1;
sync = {};
L=[];
for i=1:M
    for r=1:R
        sync{end+1} = struct('active',cell(1),'passive',cell(1));
        sync{end}.active{1} = struct('node',NaN,'class',NaN,'event',NaN);
        sync{end}.passive{1} = struct('node',NaN,'class',NaN,'event',NaN);
        sync{end}.active{1}.('node') = i;
        sync{end}.passive{1}.('node') = eps;
        sync{end}.active{1}.('class') = r;
        sync{end}.active{1}.('event') = Event.PHASE;
        sync{end}.passive{1}.('class') = r;
        sync{end}.passive{1}.('event') = [];
        sync{end}.passive{1}.('prob') = 1; % probability to sync
        %L(end+1,:) = [i, r, eps, r, Event.PHASE, 0 ];
        for j=1:M
            for s=1:R
                p = P((i-1)*R+r,(j-1)*R+s);
                if p > 0
                    sync{end+1} = struct('active',cell(1),'passive',cell(1));
                    sync{end}.active{1} = struct('node',NaN,'class',NaN,'event',NaN);
                    sync{end}.passive{1} = struct('node',NaN,'class',NaN,'event',NaN);
                    sync{end}.active{1}.('node') = i;
                    sync{end}.passive{1}.('node') = j;
                    sync{end}.active{1}.('class') = r;
                    sync{end}.active{1}.('event') = Event.DEP;
                    sync{end}.passive{1}.('class') = s;
                    sync{end}.passive{1}.('event') = Event.ARV;
                    sync{end}.passive{1}.('prob') = p; % probability to sync
                    L(end+1,:) = [i, r,   j, s, Event.DEP, Event.ARV];
                end
            end
        end
    end
end
L = unique(L,'rows');
%%
arvRates = zeros(size(SSh,1),M,R);
depRates = zeros(size(SSh,1),M,R);
Q = sparse([]);
A = length(sync);
SSq = zeros(size(SSh));
AP = []; % AP(l,1)= id of active agent for action l, AP(l,passive) = passive for action l
RL = cell(size(L,1)+1,M); % RL{l,1}(s1,s2) rate from state s1 to s2 for action l in active agent, RL{l,2}(s1p,s2p) accept probability of passive
for j=1:M
    RL{end,j}=zeros(size(qn.space{j},1));
end
for a=1:A
    node_a = sync{a}.active{1}.node;
    class_a = sync{a}.active{1}.class;
    event_a = sync{a}.active{1}.event;
    
    node_p = sync{a}.passive{1}.node;
    class_p = sync{a}.passive{1}.class;
    event_p = sync{a}.passive{1}.event; if isempty(event_p), event_p=0; end
    prob_p = sync{a}.passive{1}.prob;
    
    active = 1;
    passive = 2;
    if node_p ~= eps
        if prob_p > 0
            l = matchrow(L,[node_a, class_a, node_p, class_p, event_a, event_p]);
            AP(l,active) = node_a; % active
            AP(l,passive) = node_p;
            RL{l,active} = zeros(size(qn.space{node_a},1));
            RL{l,passive} = zeros(size(qn.space{node_p},1));
            for s=1:size(SSh,1)
                state = SSh(s,:);
                state_a = state(node_a);
                [new_state_a, rate_a] = stateAfterEventHashed( qn, node_a, state_a, event_a,class_a);
                if new_state_a > -1
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
[x, pi, Q, stats, xls, xus] = autocat(RL, AP, 'linprog','auto');
%[x,pi,Q, it, xprev] = inap(RL, AP, 1e-6, 1000);
