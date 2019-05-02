function [QN,UN,RN,TN,CN,XN] = solver_mam(qn, PH, options)
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

chain = zeros(1,K);
for k=1:K
    chain(k) = find(qn.chains(:,k));
end


if M>=2 && all(isinf(N))
    % open queueing system (one node is the external world)
    BuToolsVerbose = false;
    BuToolsCheckInput = true;
    BuToolsCheckPrecision = 1e-12;
    
    pie = {};
    D0 = {};
    for ist=1:M
        switch qn.sched{ist}
            case SchedStrategy.EXT
                TN(ist,:) = qn.rates(ist,:);
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
    end
    
    it_max = options.iter_max;
    for it=1:it_max
        % now estimate arrival processes
        
        if it == 1
            % initially form departure processes using scaled service
            DEP = PH;
            for ind=1:M
                for r=1:K
                    ist = qn.nodeToStation(ind);
                    DEP{ind,r} = map_scale(PH{ist,r}, 1 / (lambda(r) * V(ind,r)) );
                end
            end
        else
            % at successive iteration, use a mixture of the service process
            for ind=1:M
                switch qn.nodetype(ind)
                    case NodeType.Queue
                        ist = qn.nodeToStation(ind);
                        
                        %MIX = {ARV{ist},PH{ist,1:K}}; pmix = [1-sum(UN(ist,:)), UN(ist,:)];
                        MIX = {PH{ist,1:K}}; pmix = QN(ist,:);
                        
                        MMAPdep = mmap_mixture(pmix/sum(pmix),MIX);
                        for r=1:K
                            DEP{ind,r} = {MMAPdep{1}+MMAPdep{2}-MMAPdep{2+r},MMAPdep{2+r}};
                            DEP{ind,r} = map_scale(DEP{ind,r}, 1 / (lambda(r) * V(ind,r)) );
                        end
                end
            end
        end
        
        config = struct();
        config.merge = 'super';
        %config.merge = 'mixture';
        %config.merge = 'interpos';
        config.compress = 'none';
        
        config.space_max = 16;
        ARV = solver_mam_estflows(qn, DEP, config);
        QN_1 = QN;
        
        for ist=1:M
            ind = qn.stationToNode(ist);
            switch qn.nodetype(ind)
                case NodeType.Queue
                    sum(mmap_idc(ARV{ind}),2)
                    if length(ARV{ind}{1}) > config.space_max
                        %ARV{ind} = mamap2m_fit_gamma_fb_mmap(ARV{ind});
                        %ARV{ind} = mamap2m_fit_mmap(ARV{ind});
                        %ARV{ind} = mmap_mixture_fit_mmap(ARV{ind});
                        ARV{ind} = m3pp2m_fit_count_theoretical(ARV{ind}, 'approx_cov', 1, 1e6);
                        ARV{ind} = mmap_normalize(ARV{ind});
                    end
                    sum(mmap_idc(ARV{ind}),2)
                    [Qret{1:K}] = MMAPPH1FCFS({ARV{ind}{[1,3:end]}}, {pie{ist,:}}, {D0{ist,:}}, 'ncMoms', 1);
                    QN(ist,:) = cell2mat(Qret);
                    TN(ist,:) = mmap_lambda(ARV{ind});
            end
        end
        
        for ist=1:M
            for k=1:K
                UN(ist,k) = TN(ist,k) * map_mean(PH{ist,k});
                % add number of jobs at the surrogate delay server
                QN(ist,k) = QN(ist,k) + TN(ist,k)*(map_mean(PH{ist,k})*qn.nservers(ist)) * (qn.nservers(ist)-1)/qn.nservers(ist);
                RN(ist,k) = QN(ist,k) ./ TN(ist,k);
            end
        end
        
        if max(abs(QN(:)-QN_1(:))./QN_1(:)) < options.iter_tol
            break;
        end
    end
    
else
    warning('This model is not supported by SolverMAM yet. Returning with no result.');
end

end
