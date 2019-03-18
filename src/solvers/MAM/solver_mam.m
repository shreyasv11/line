function [Q,U,R,T,C,X] = solver_mam(qn, PH, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

global BuToolsVerbose;
global BuToolsCheckInput;
global BuToolsCheckPrecision;
%% generate local state spaces
M = qn.nstations;
K = qn.nclasses;
N = qn.njobs';
rt = qn.rt;
V = qn.visits;

Q = zeros(M,K);
U = zeros(M,K);
R = zeros(M,K);
T = zeros(M,K);
C = zeros(1,K);
X = zeros(1,K);

if M==2 && K==1 && all(isinf(N))
    % single-class open queueing system (one node is the external world)
    idx = -1;
    for i=1:M
        switch qn.sched{i}
            case SchedStrategy.EXT
                A = PH{i,1}; A{1} = V{1}(i) * A{1}; A{2} = V{1}(i) * A{2};
            case SchedStrategy.FCFS
                PHs = PH{i,1}; PHs{1} = V{1}(i) * PHs{1}; PHs{2} = V{1}(i) * PHs{2};
                idx = i;
            otherwise
                error('Unsupported scheduling strategy');
        end
    end
    [X, q, u, pqueue, Rmat, eta] = qbd_mapmap1(A,PHs);
    T(idx,1) = X;
    Q(idx,1) = q;
    U(idx,1) = u;
    R(idx,1) = Q(idx,1) / X;
    C = R;
elseif M==2 && K>1 && all(isinf(N))
    % multi-class open queueing system (one node is the external world)
    BuToolsVerbose = false;
    BuToolsCheckInput = true;
    BuToolsCheckPrecision = 1e-12;
    pie = {};
    S = {};
    for i=1:M
        switch qn.sched{i}
            case SchedStrategy.EXT
                na = cellfun(@(x) length(x{1}),{PH{i,:}});
                A = {PH{i,1}{1},PH{i,1}{2},PH{i,1}{2}};
                for k=2:K
                    A = mmap_super(A,{PH{i,k}{1},PH{i,k}{2},PH{i,k}{2}});
                end
                idx_arv = i;
            case {SchedStrategy.FCFS, SchedStrategy.HOL}
                row = size(S,1) + 1;
                for k=1:K
                    PH{i,k} = map_scale(PH{i,k}, map_mean(PH{i,k})/qn.nservers(i));
                    pie{k} = map_pie(PH{i,k});
                    S{k} = PH{i,k}{1};
                end
                idx_q = i;
            otherwise
                error('Unsupported scheduling strategy');
        end
    end
    
    if any(qn.classprio ~= qn.classprio(1)) % if priorities are not identical
        [uK,iK] = unique(qn.classprio);
        if length(uK) == length(qn.classprio) % if all priorities are different
            [Qret{iK}] = MMAPPH1NPPR({A{[1;2+iK]}}, {pie{iK}}, {S{iK}}, 'ncMoms', 1);
        else
            error('Solver MAM requires either identical priorities or all distinct priorities');
        end
    else
        [Qret{1:K}] = MMAPPH1FCFS({A{[1,3:end]}}, {pie{:}}, {S{:}}, 'ncMoms', 1);
    end
    Q(idx_q,:) = cell2mat(Qret);
    T(idx_arv,:) = mmap_count_lambda(A);
    T(idx_q,:) = T(idx_arv,:);
    R(idx_q,:) = Q(idx_q,:) ./ T(idx_q,:);
    for k=1:K
        U(idx_q,k) = T(idx_q,k) / map_lambda(PH{i,k});
    end
    C = R;
end

end