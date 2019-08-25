function refreshAG(self)
% REFRESHAG()
% Export network in stochastic agent representation

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

% We now generate the global state space
% parses all but the service processes
qn = self.getStruct;
nnodes = qn.nnodes;
nstateful = qn.nstateful;
nclasses = qn.nclasses;
A = length(qn.sync);
%%
active = 1; % column of active actions
passive = 2; % columns of passive actions
eps = nnodes+1; % row of local actions
sync = qn.sync;
actionTable=zeros(A,6);
%[~,eventFilt]=SolverCTMC(self,'cutoff',3,'force',true).getGenerator()
for a=1:A
    actionTable(a,:) = [sync{a}.active{1}.node, sync{a}.active{1}.class, sync{a}.passive{1}.node, sync{a}.passive{1}.class, sync{a}.active{1}.event, sync{a}.passive{1}.event];
    AP(a,[active,passive]) = [sync{a}.active{1}.node, sync{a}.passive{1}.node];
    %    eventFilt{a}
end
%actionTable = unique(actionTable,'rows');
[stateSpace,nodeStateSpace] = model.getStateSpace;
actionTable
%%
SSh=[];
RL = cell(size(actionTable,1)+1,nstateful); % RL{a,active}(s1,s2) rate from state s1 to s2 for action a in active agent, RL{a,passive}(s1p,s2p) accept probability of passive
for j=1:nnodes
    if qn.isstateful(j)
        jsf = qn.nodeToStateful(j);
        RL{end,j}=zeros(size(qn.space{jsf},1));
    end
end

issim = false;
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
            for s=1:size(space{node_a},1)
                state_a = space{node_a}(s,:);
                [new_state_a, rate_a] = State.afterEvent( qn, node_a, state_a, event_a, class_a, issim);
                if new_state_a>0
                    RL{l,active}(state_a,new_state_a)=rate_a;
                    
                    node_p = sync{a}.passive{1}.node;
                    state_p = state(node_p);
                    if node_p == node_a %self-loop
                        [new_state_p, ~] = State.afterEvent( qn, node_p, new_state_a, event_p, class_p, issim);
                    else
                        [new_state_p, ~] = State.afterEvent( qn, node_p, state_p, event_p, class_p, issim);
                    end
                    RL{l,passive}(state_p,new_state_p)=prob_p;
                end
            end
        end
    else % local transitions
        for a=1:size(SSh,1)
            state = SSh(a,:);
            state_a = state(node_a);
            [new_state_a, rate_a] = State.afterEvent(qn, node_a, state_a, event_a, class_a, issim);
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
