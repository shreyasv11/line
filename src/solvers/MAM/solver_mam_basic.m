function [QN,UN,RN,TN,CN,XN] = solver_mam_basic(qn, PH, options)
% [Q,U,R,T,C,X] = SOLVER_MAM(QN, PH, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

global BuToolsVerbose;
global BuToolsCheckInput;
global BuToolsCheckPrecision;

%% generate local state spaces
I = qn.nnodes;
M = qn.nstations;
K = qn.nclasses;
C = qn.nchains;
N = qn.njobs';
V = cellsum(qn.visits);

QN = zeros(M,K);
UN = zeros(M,K);
RN = zeros(M,K);
TN = zeros(M,K);
CN = zeros(1,K);
XN = zeros(1,K);

lambda = zeros(1,K);
for c=1:C
    inchain = find(qn.chains(c,:));
    lambdas_inchain = qn.rates(qn.refstat(inchain(1)),inchain);
    lambdas_inchain = lambdas_inchain(isfinite(lambdas_inchain));
    lambda(inchain) = sum(lambdas_inchain);
end

if M>=2 && all(isinf(N))
    % open queueing system (one node is the external world)
    BuToolsVerbose = false;
    BuToolsCheckInput = true;
    BuToolsCheckPrecision = 1e-12;
    pie = {};
    D0 = {};
    % first build the joint arrival process
    for ist=1:M
        switch qn.sched{ist}
            case SchedStrategy.EXT
                % form a MMAP for the arrival process from all classes
                if isnan(PH{ist,1}{1})
                    PH{ist,1} = map_exponential(Inf); % no arrivals from this class
                end
                chainArrivalAtSource = cell(1,C);
                for c=1:C %for each chain
                    inchain = find(qn.chains(c,:))';
                    chainArrivalAtSource{c} = {PH{ist,1}{1},PH{ist,1}{2},PH{ist,1}{2}};
                    for ki=2:length(inchain)
                        k = inchain(ki);
                        if isnan(PH{ist,k}{1})
                            PH{ist,k} = map_exponential(Inf); % no arrivals from this class
                        end
                        chainArrivalAtSource{c} = mmap_super(chainArrivalAtSource{c},{PH{ist,k}{1},PH{ist,k}{2},PH{ist,k}{2}});
                    end
                    if c == 1
                        aggrArrivalAtSource = chainArrivalAtSource{1};
                    else
                        aggrArrivalAtSource = mmap_super(aggrArrivalAtSource,chainArrivalAtSource{c});
                    end
                end
                TN(ist,:) = mmap_count_lambda(aggrArrivalAtSource);
                TN(ist,isnan(TN(ist,:)))=0;
            case {SchedStrategy.FCFS, SchedStrategy.HOL, SchedStrategy.PS}
                for k=1:K
                    % divide service time by number of servers and put
                    % later a surrogate delay server in tandem to compensate
                    PH{ist,k} = map_scale(PH{ist,k}, map_mean(PH{ist,k})/qn.nservers(ist));
                    pie{ist,k} = map_pie(PH{ist,k});
                    D0{ist,k} = PH{ist,k}{1};
                end
        end
    end % i
    
    % at the first iteration, propagate the arrivals with the same
    for ind=1:I
        if qn.isstation(ind)
            ist = qn.nodeToStation(ind);
            switch qn.sched{ist}
                case SchedStrategy.INF
                    for k=1:K
                        RN(ist,k) = map_mean(PH{ist,k});
                        TN(ist,k) = TN(qn.refstat(k),k);
                        QN(ist,k) = TN(qn.refstat(k),k).*RN(ist,k);
                        UN(ist,k) = QN(ist,k);
                    end
                case SchedStrategy.PS
                    for k=1:K
                        UN(ist,k) = map_mean(PH{ist,k})*TN(qn.refstat(k),k);
                        RN(ist,k) = map_mean(PH{ist,k})/(1-UN(ist,k));
                        TN(ist,k) = TN(qn.refstat(k),k)*V(ist,k);
                        QN(ist,k) = TN(qn.refstat(k),k).*RN(ist,k);
                    end
                case {SchedStrategy.FCFS, SchedStrategy.HOL}
                    Qret = {};
                    if any(qn.classprio ~= qn.classprio(1)) % if priorities are not identical
                        [uK,iK] = unique(qn.classprio);
                        if length(uK) == length(qn.classprio) % if all priorities are different
                            [Qret{iK}] = MMAPPH1NPPR({aggrArrivalAtSource{[1;2+iK]}}, {pie{ist,iK}}, {D0{ist,iK}}, 'ncMoms', 1);
                        else
                            error('Solver MAM requires either identical priorities or all distinct priorities');
                        end
                    else
                        chainArrivalAtNode = cell(1,C);
                        rates_i = V(ist,:) .* map_lambda(aggrArrivalAtSource);
                        for c=1:C %for each chain
                            inchain = find(qn.chains(c,:))';
                            chainArrivalAtNode{c} = mmap_mark(chainArrivalAtSource{c}, rates_i(inchain) / sum(rates_i(inchain)));
                            chainArrivalAtNode{c} = mmap_scale(chainArrivalAtNode{c}, 1./rates_i);
                            if c == 1
                                aggrArrivalAtNode = chainArrivalAtNode{1};
                            else
                                aggrArrivalAtNode = mmap_super(aggrArrivalAtNode,chainArrivalAtNode{c});
                            end
                        end
                        Qret = {};                        
                        %sum(mmap_idc(aggrArrivalAtNode),2)
                        [Qret{1:K}] = MMAPPH1FCFS({aggrArrivalAtNode{[1,3:end]}}, {pie{ist,:}}, {D0{ist,:}}, 'ncMoms', 1);
                    end
                    QN(ist,:) = cell2mat(Qret);
                    for k=1:K
                        TN(ist,k) = rates_i(k);
                        UN(ist,k) = TN(ist,k) * map_mean(PH{ist,k});
                        % add number of jobs at the surrogate delay server
                        QN(ist,k) = QN(ist,k) + TN(ist,k)*(map_mean(PH{ist,k})*qn.nservers(ist)) * (qn.nservers(ist)-1)/qn.nservers(ist);
                        RN(ist,k) = QN(ist,k) ./ TN(ist,k);
                    end
            end
        else % not a station
            switch qn.nodetype(ind)
                case NodeType.Fork
                    
            end
        end
    end
    CN = sum(RN,1);
else
    warning('This model is not supported by SolverMAM yet. Returning with no result.');
end

end
