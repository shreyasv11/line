
% Getting started example from the LINE documentation
model = Network('stateTest1');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'Queue1', SchedStrategy.PS);
station{3} = Queue(model, 'Queue2', SchedStrategy.FCFS);

N(1) = 2; jobclass{1} = ClosedClass(model, 'ClassA', N(1), station{1});

rate = [10; 20; 30];
for i=1:length(station)
    for r=1:length(jobclass)
        station{i}.setService(jobclass{r}, Exp(rate(i,r)));
    end
end

P{1} = zeros(3); P{1}(1,1:3) = [0.0, 0.5, 0.5]; P{1}(2,[1,2])=[1.0,0.0]; P{1}(3,1) = 1.0; % type-A
V1=dtmc_solve(P{1}); V1=V1/V1(1);
model.link(P);
[M,R,C] = model.getSize();
qn = model.getStruct();


%% generate local state spaces
space = {};
spacesz = [];
for i=1:M
    qn.cap(i,1) = sum(N);
    qn.classcap(i,:) = N;
    qn.space{i} = stateFromMarginalBounds(qn, i, [], N);
    if isinf(qn.nservers(i))
        qn.nservers(i) = sum(N);
    end
    spacesz(i) = size(qn.space{i},1);
end
%%
tic;
J = stateClosedMulti(M,N);
clearAllMemoizedCaches;
wantMemoization = false;
for i=1:M
    if ~wantMemoization
        mstateAfterEventHashed{i} = @(x,y,z) stateAfterEventHashed(qn,i,x,y,z);
        mstatesFromMarginalState{i} = @(x) stateFromMarginal(qn,i,x);
        mstateHash{i} = @(x) stateHash(qn,i,x);
    else
        mstateAfterEventHashed{i} = memoize(@(x,y,z) stateAfterEventHashed(qn,i,x,y,z));
        mstatesFromMarginalState{i} = memoize(@(x) stateFromMarginal(qn,i,x));
        mstateHash{i} = memoize(@(x) stateHash(qn,i,x));
        mstateAfterEventHashed{i}.CacheSize = 1e4;
        mstatesFromMarginalState{i}.CacheSize = 1e4;
        mstateHash{i}.CacheSize = 1e4;
    end
end

for j=1:size(J,1)
    for i=1:M
        v = mstatesFromMarginalState{i}(J(j,i:M:end));
        netstates{j,i} = mstateHash{i}(v);
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
        try
            ctr = ctr + 1;
            % build state
            for i=1:length(n)
                u{i} = qn.space{i}(v{i}(1+n(i)),:);
                h{i} = v{i}(1+n(i));
            end
            SS(ctr,:)=cell2mat(u);
            SSh(ctr,:)=cell2mat(h);
        end
        n = pprod(n,vN);
    end
end
%%
eps = M+1;
sync = {};
P = model.getRoutingMatrix();  %%% INCORRECT FOR OPEN CS - use qn structure
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
                end
            end
        end
    end
end

%%
Q = sparse([]);
A = length(sync);
SSv = {};
for s=1:size(SSh,1)
    state = SSh(s,:);
    for a=1:A
        node_a = sync{a}.active{1}.node;
        state_a = state(node_a);
        class_a = sync{a}.active{1}.class;
        event_a = sync{a}.active{1}.event;
        [new_state_a, rate_a] = mstateAfterEventHashed{node_a}(state_a,event_a,class_a);
        
        node_p = sync{a}.passive{1}.node;
        if node_p ~= eps
            state_p = state(node_p);
            class_p = sync{a}.passive{1}.class;
            event_p = sync{a}.passive{1}.event;
            prob_p = sync{a}.passive{1}.prob;
            if prob_p > 0
                if node_p == node_a %self-loop
                    [new_state_p, ~] = mstateAfterEventHashed{node_p}(new_state_a, event_p, class_p);
                else
                    [new_state_p, ~] = mstateAfterEventHashed{node_p}(state_p, event_p, class_p);
                end
            end
        end
        for ai=1:length(new_state_a)
            if ~isempty(new_state_a(ai))
                if node_p == eps
                    new_state = state;
                    new_state(node_a) = new_state_a(ai);
                    prob_p = 1;
                elseif ~isempty(new_state_p)
                    new_state = state;
                    new_state(node_a) = new_state_a(ai);
                    new_state(node_p) = new_state_p;
                end
                ns = matchrow(SSh, new_state);
                if ns>0
                    if ~isnan(rate_a)
                        Q(s,ns) = rate_a(ai) * prob_p;
                    end
                end
            end
        end
    end
end
zero_row = find(sum(Q,2)==0);
zero_col = find(sum(Q,1)==0);
Q = ctmc_makeinfgen(Q);
Q(zero_row,zero_row) = -eye(length(zero_row));
Q(zero_col,zero_col) = -eye(length(zero_col));


[Qlen,Util,Wait,Tput] = model.getAvgHandles();
options.verbose = 1;
options.keep = true;
options.samples = 1e4;

solver = SolverMVA(model,options);
[QN,UN,WN,TN] = solver.getAvg(Qlen,Util,Wait,Tput);
QN

% for s1=1:size(Q,1)
% state=full(Q(s1,:));
% for t=find(state>0),
%     fprintf('from: %s\n to : %s\nrate: %d\n\n',num2str(SS(s1,:)),num2str(full(SS(t,:))),full(Q(s1,t)));
% end
% end

if exist('pfqn_prob.m','file')
    pi=ctmc_solve(full(Q));
    D=1./rate.*[V1(:)];
    D(isnan(D))=0;
    Z=D(1,:);
    D=D(2:M,:);
    pfqn_prob([0;0],D,N,Z)
    full1 = sum(SS(:,(phases*R+1):end),2)==0;
    sum(pi(full1))
end
