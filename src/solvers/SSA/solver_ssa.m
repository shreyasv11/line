function [pi,SSq,arvRates,depRates]=solver_ssa(qn,options)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

% by default the jobs are all initialized in the first valid state
%% generate local state spaces
nstations = qn.nstations;
nstateful = qn.nstateful;
R = qn.nclasses;
N = qn.njobs';
sync = qn.sync;
csmask = qn.csmask;

cutoff = options.cutoff;
if prod(size(cutoff))==1
    cutoff = cutoff * ones(qn.nstations, qn.nclasses);
end

%%
Np = N';
capacityc = zeros(qn.nnodes, qn.nclasses);
for ind=1:qn.nnodes
    if qn.isstation(ind) % place jobs across stations
        ist = qn.nodeToStation(ind);
        isf = qn.nodeToStateful(ind);
        for r=1:qn.nclasses %cut-off open classes to finite capacity
            c = find(qn.chains(:,r));
            if ~isempty(qn.visits{c}) && qn.visits{c}(ist,r) == 0
                capacityc(ind,r) = 0;
            elseif any(isnan(qn.mu{ist,r})) % disabled
                capacityc(ind,r) = 0;
            else
                if isinf(N(r))
                    capacityc(ind,r) =  min(cutoff(ist,r), qn.classcap(ist,r));
                else
                    capacityc(ind,r) =  sum(qn.njobs(qn.chains(c,:)));
                end
            end
        end
        if isinf(qn.nservers(ist))
            qn.nservers(ist) = sum(capacityc(ind,:));
        end
    elseif qn.isstateful(ind) % generate state space of other stateful nodes that are not stations
        isf = qn.nodeToStateful(ind);
        ist = qn.nodeToStation(ind);
        switch qn.nodetype(ind)
            case NodeType.Cache
                for r=1:qn.nclasses % restrict state space generation for immediate events
                    if isnan(qn.varsparam{ind}.pref{r})
                        capacityc(ind,r) =  0; %
                    else
                        capacityc(ind,r) =  1; %
                    end
                end
            otherwise
                capacityc(ind,:) =  1; %
        end
    end
end

%%
if any(isinf(Np))
    Np(isinf(Np)) = 0;
end

init_state_hashed = ones(1,nstateful); % pick the first state in space{i}

%%
arvRatesSamples = zeros(options.samples,nstateful,R);
depRatesSamples = zeros(options.samples,nstateful,R);
A = length(sync);
samples_collected = 1;
state = init_state_hashed;
stateCell = cell(nstateful,1);
nir = {};
for ind=1:qn.nnodes
    if qn.isstateful(ind)
        isf = qn.nodeToStateful(ind);
        stateCell{isf} = qn.space{isf}(state(isf),:);
        if qn.isstation(ind)
            ist = qn.nodeToStation(ind);
            [~,nir{ist}] = State.toMarginal(qn, ind, qn.space{isf}(state(isf),:));
            nir{ist} = nir{ist}(:);
        end
    end
end

state = cell2mat(stateCell');
output = zeros(1+length(state),samples_collected);
output(1:(1+length(state)),1) = [0, state]';
SSq = cell2mat(nir');
local = qn.nnodes+1;
last_node_a = 0;
last_node_p = 0;
for act=1:A
    node_a{act} = sync{act}.active{1}.node;
    node_p{act} = sync{act}.passive{1}.node;
    class_a{act} = sync{act}.active{1}.class;
    class_p{act} = sync{act}.passive{1}.class;
    event_a{act} = sync{act}.active{1}.event;
    event_p{act} = sync{act}.passive{1}.event;
    outprob_a{act} = [];
    outprob_p{act} = [];
end
newStateCell = cell(1,A);
isSimulation = true; % allow state vector to grow, e.g. for FCFS buffers
while samples_collected < options.samples    
    %samples_collected
    ctr = 1;
    enabled_action = {}; % row is action label, col1=rate, col2=new state
    enabled_new_state = {};
    enabled_rates = [];
    for act=1:A
        update_cond_a = true; %((node_a{act} == last_node_a || node_a{act} == last_node_p));
        newStateCell{act} = stateCell;
        if update_cond_a || isempty(outprob_a{act})
            isf = qn.nodeToStateful(node_a{act});            
            [newStateCell{act}{qn.nodeToStateful(node_a{act})}, rate_a{act}, outprob_a{act}] =  State.afterEvent(qn, node_a{act}, stateCell{isf}, event_a{act}, class_a{act}, isSimulation);
        end
        
        if isempty(newStateCell{act}{qn.nodeToStateful(node_a{act})}) || isempty(rate_a{act}) % state not found
            continue
        end
        
        for ia=1:size(newStateCell{act}{qn.nodeToStateful(node_a{act})},1) % for all possible new states
            if newStateCell{act}{qn.nodeToStateful(node_a{act})}(ia,:) == -1 % hash not found
                continue
            end
            update_cond_p = ((node_p{act} == last_node_a || node_p{act} == last_node_p)) || isempty(outprob_p{act});
            update_cond = true; %update_cond_a || update_cond_p;
            if rate_a{act}(ia)>0
                if node_p{act} ~= local
                    if node_p{act} == node_a{act} %self-loop
                        if update_cond
                            [newStateCell{act}{qn.nodeToStateful(node_p{act})}, ~, outprob_p{act}] =  State.afterEvent(qn, node_p{act}, newStateCell{act}{qn.nodeToStateful(node_a{act})}, event_p{act}, class_p{act}, isSimulation);
                        end
                    else % departure
                        if update_cond
                            [newStateCell{act}{qn.nodeToStateful(node_p{act})}, ~, outprob_p{act}] =  State.afterEvent(qn, node_p{act}, newStateCell{act}{qn.nodeToStateful(node_p{act})}, event_p{act}, class_p{act}, isSimulation);
                        end
                    end
                       if ~isempty(newStateCell{act}{qn.nodeToStateful(node_p{act})})
                        if qn.isstatedep(node_a{act},3)
                            prob_sync_p{act} = sync{act}.passive{1}.prob(stateCell, newStateCell{act}); %state-dependent
                        else
                            prob_sync_p{act} = sync{act}.passive{1}.prob;
                        end
                    else
                        prob_sync_p{act} = 0;
                    end
                end
                if ~isempty(newStateCell{act}{qn.nodeToStateful(node_a{act})})
                    if node_p{act} == local
                        prob_sync_p{act} = 1; %outprob_a{act}; % was 1
                    end
                    if ~isnan(rate_a{act})
                        if all(~cellfun(@isempty,newStateCell{act}))
                            if event_a{act} == Event.DEP
                                node_a_sf{act} = qn.nodeToStateful(node_a{act});
                                node_p_sf{act} = qn.nodeToStateful(node_p{act});
                                depRatesSamples(samples_collected,node_a_sf{act},class_a{act}) = depRatesSamples(samples_collected,node_a_sf{act},class_a{act}) + outprob_a{act} * outprob_p{act} * rate_a{act}(ia) * prob_sync_p{act};
                                arvRatesSamples(samples_collected,node_p_sf{act},class_p{act}) = arvRatesSamples(samples_collected,node_p_sf{act},class_p{act}) + outprob_a{act} * outprob_p{act} * rate_a{act}(ia) * prob_sync_p{act};
                            end
                            if any(~cellfun(@isequal,newStateCell{act},stateCell))
                                if node_p{act} < local && ~csmask(class_a{act}, class_p{act}) && qn.nodetype(node_p{act})~=NodeType.Source && (rate_a{act}(ia) * prob_sync_p{act} >0)
                                    error('Fatal error: state-dependent routing at node %d violates class switching mask (node %d -> node %d, class %d -> class %d).', node_a{act}, node_a{act}, node_p{act}, class_a{act}, class_p{act});
                                end
                                enabled_rates(ctr) = rate_a{act}(ia) * prob_sync_p{act};
                                enabled_action{ctr} = act;
                                %enabled_new_state{ctr} = new_state;
                                ctr = ctr + 1;
                            end
                        end
                    end
                end
            end
        end
    end
    
    tot_rate = sum(enabled_rates);
    cum_rate = cumsum(enabled_rates) / tot_rate;
    firing_ctr = 1 + max([0,find( rand > cum_rate )]); % select action
    last_node_a = node_a{enabled_action{firing_ctr}};
    last_node_p = node_p{enabled_action{firing_ctr}};
    state = cell2mat(stateCell');
    output(1:(1+length(state)),samples_collected) = [-(log(rand)/tot_rate), state]';

    for ind=1:qn.nnodes
        if qn.isstation(ind)
            isf = qn.nodeToStateful(ind);
            ist = qn.nodeToStation(ind);
            [~,nir{ist}] = State.toMarginal(qn, ind, stateCell{isf});
            nir{ist}=nir{ist}(:);
        end
    end
    SSq(:,samples_collected) = cell2mat(nir');
    
    samples_collected = samples_collected + 1;
    stateCell = newStateCell{enabled_action{firing_ctr}};
    if options.verbose
        if samples_collected == 1e2
            fprintf(1,sprintf('SSA samples: %6d',samples_collected));
        elseif options.verbose == 2
            if samples_collected == 0
                fprintf(1,sprintf('SSA samples: %6d',samples_collected));
            else
                fprintf(1,sprintf('\b\b\b\b\b\b%6d',samples_collected));
            end
        elseif mod(samples_collected,1e2)==0 || options.verbose == 2
            fprintf(1,sprintf('\b\b\b\b\b\b%6d',samples_collected));
        end
    end
end

%transient = min([floor(samples_collected/10),1000]); % remove first part of simulation (10% of the samples up to 1000 max)
%transient = 0;
%output = output((transient+1):end,:);
output = output';
[u,ui,uj] = unique(output(:,2:end),'rows');
arvRates = zeros(size(u,1),qn.nstateful,R);
depRates = zeros(size(u,1),qn.nstateful,R);

pi = zeros(1,size(u,1));
for s=1:size(u,1)
    pi(s) = sum(output(uj==s,1));    
end
SSq = SSq(:,ui)';

for ind=1:qn.nnodes
    if qn.isstateful(ind)
        isf = qn.nodeToStateful(ind);
        if qn.isstation(ind)
            ist = qn.nodeToStation(ind);
            K = max(qn.phases(ist,:),ones(size(qn.phases(ist,:)))); % disabled classes still occupy 1 state element
            Ks = [0,cumsum(K)];
        end
        for s=1:size(u,1)
            for r=1:R
                arvRates(s,isf,r) = arvRatesSamples(ui(s),isf,r); % we just need one sample
                depRates(s,isf,r) = depRatesSamples(ui(s),isf,r); % we just need one sample
            end
        end
    end
end
pi = pi/sum(pi);
if options.verbose
    fprintf(1,'\n');
end
end
