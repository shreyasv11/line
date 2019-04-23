function [QN,UN,RN,TN,CN,XN] = solver_mam(qn, PH, options)
% [Q,U,R,T,C,X] = SOLVER_MAM(QN, PH, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

global BuToolsVerbose;
global BuToolsCheckInput;
global BuToolsCheckPrecision;
%% generate local state spaces
M = qn.nstations;
K = qn.nclasses;
C = qn.nchains;
N = qn.njobs';
V = qn.visits;
Pnodes = qn.rtnodes;

QN = zeros(M,K);
UN = zeros(M,K);
RN = zeros(M,K);
TN = zeros(M,K);
CN = zeros(1,K);
XN = zeros(1,K);

chain = zeros(1,K);
for k=1:K
    chain(k) = find(qn.chains(:,k));
end

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
    for i=1:M
        switch qn.sched{i}
            case SchedStrategy.EXT
                % form a MMAP of the arrival process
                if isnan(PH{i,1}{1})
                    PH{i,1} = map_exponential(Inf); % no arrivals from this class
                end
                A = {PH{i,1}{1},PH{i,1}{2},PH{i,1}{2}};
                for k=2:K
                    if isnan(PH{i,k}{1})
                        PH{i,k} = map_exponential(Inf); % no arrivals from this class
                    end
                    A = mmap_super(A,{PH{i,k}{1},PH{i,k}{2},PH{i,k}{2}});
                end
                TN(i,:) = mmap_count_lambda(A);
                TN(i,isnan(TN(i,:)))=0;
            case {SchedStrategy.FCFS, SchedStrategy.HOL, SchedStrategy.PS}
                for k=1:K
                    PH{i,k} = map_scale(PH{i,k}, map_mean(PH{i,k})*V{chain(k)}(i,k)/qn.nservers(i));
                    pie{i,k} = map_pie(PH{i,k});
                    D0{i,k} = PH{i,k}{1};
                end
        end
    end % i
    
    for i=1:M
        switch qn.sched{i}
            case SchedStrategy.INF
                for k=1:K
                    RN(i,k) = map_mean(PH{i,k});
                    TN(i,k) = TN(qn.refstat(k),k);
                    QN(i,k) = TN(qn.refstat(k),k).*RN(i,k);
                    UN(i,k) = QN(i,k);
                end
            case SchedStrategy.PS
                for k=1:K
                    UN(i,k) = map_mean(PH{i,k})*TN(qn.refstat(k),k);
                    RN(i,k) = map_mean(PH{i,k})/(1-UN(i,k));
                    TN(i,k) = TN(qn.refstat(k),k)*V{chain(k)}(i,k);
                    QN(i,k) = TN(qn.refstat(k),k).*RN(i,k);
                end
            case {SchedStrategy.FCFS, SchedStrategy.HOL}
                Qret = {};
                if any(qn.classprio ~= qn.classprio(1)) % if priorities are not identical
                    [uK,iK] = unique(qn.classprio);
                    if length(uK) == length(qn.classprio) % if all priorities are different
                        [Qret{iK}] = MMAPPH1NPPR({A{[1;2+iK]}}, {pie{i,iK}}, {D0{i,iK}}, 'ncMoms', 1);
                    else
                        error('Solver MAM requires either identical priorities or all distinct priorities');
                    end
                else
                    [Qret{1:K}] = MMAPPH1FCFS({A{[1,3:end]}}, {pie{i,:}}, {D0{i,:}}, 'ncMoms', 1);
                end
                QN(i,:) = cell2mat(Qret);
                for k=1:K
                    TN(i,k) = TN(qn.refstat(k),k)*V{chain(k)}(i,k);
                    UN(i,k) = TN(qn.refstat(k),k) * map_mean(PH{i,k});
                    % correct with number of jobs at the follow up delay
                    QN(i,k) = QN(i,k) + TN(qn.refstat(k),k)*(map_mean(PH{i,k})*qn.nservers(i)) * (qn.nservers(i)-1)/qn.nservers(i);
                    RN(i,k) = QN(i,k) ./ TN(qn.refstat(k),k);
                end
        end
    end
    CN = sum(RN,1);
else
    warning('This model is not supported by SolverMAM yet. Returning with no result.');
end

end
