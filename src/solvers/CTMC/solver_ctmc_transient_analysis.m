function [t,QNt,UNt,RNt,TNt,CNt,XNt,runtime,fname] = solver_ctmc_transient_analysis(qn, options)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

RNt=[]; CNt=[];  XNt=[];

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
fname = '';
rt = qn.rt;
mu = qn.mu;
phi = qn.phi;
S = qn.nservers;
NK = qn.njobs';  % initial population per class
sched = qn.sched;

Tstart = tic;

PH=cell(M,K);
for i=1:M
    for k=1:K
        if isempty(mu{i,k})
            PH{i,k} = [];
        elseif length(mu{i,k})==1
            PH{i,k} = map_exponential(1/mu{i,k});
        else
            D0 = diag(-mu{i,k})+diag(mu{i,k}(1:end-1).*(1-phi{i,k}(1:end-1)),1);
            D1 = zeros(size(D0));
            D1(:,1)=(phi{i,k}.*mu{i,k});
            PH{i,k} = map_normalize({D0,D1});
        end
    end
end

myP = cell(K,K);
for k = 1:K
    for c = 1:K
        myP{k,c} = zeros(M);
    end
end

for i=1:M
    for j=1:M
        for k = 1:K
            for c = 1:K
                % routing table for each class
                myP{k,c}(i,j) = rt((i-1)*K+k,(j-1)*K+c);
            end
        end
    end
end

[Q,SS,SSq,arvRates,depRates,qn] = solver_ctmc(qn, options); % qn is updated with the state space

if options.keep
    fname = tempname;
    save([fname,'.mat'],'Q','SSq')
    fprintf(1,'CTMC generator and state space saved in: ');
    disp([fname, '.mat'])
end

state = [];
for i=1:qn.nnodes
    if qn.isstateful(i)
        isf = qn.nodeToStateful(i);
        state = [state,zeros(1,size(qn.space{isf},2)-length(qn.state{isf})),qn.state{isf}];
    end
end
pi0 = zeros(1,length(Q));
pi0(matchrow(SS,state)) = 1; % find initial state and set it to probability 1

%if options.timespan(1) == options.timespan(2)
%    pit = ctmc_uniformization(pi0,Q,options.timespan(1));
%    t = options.timespan(1);
%else
[pit,t] = ctmc_transient(Q,pi0,options.timespan(1),options.timespan(2),options.stiff);
%end
pit(pit<1e-14)=0;

QNt = cell(M,K);
UNt = cell(M,K);
%XNt = cell(1,K);
TNt = cell(M,K);

for k=1:K
    %    XNt(k) = pi*arvRates(:,qn.refstat(k),k);
    for i=1:M
        TNt{i,k} = pit*depRates(:,i,k);
        QNt{i,k} = pit*SSq(:,(i-1)*K+k);
        switch sched{i}
            case SchedStrategy.INF
                UNt{i,k} = QNt{i,k};
            otherwise
                % we use Little's law, otherwise there are issues in
                % estimating the fraction of time assigned to class k (to
                % recheck)
                if ~isempty(PH{i,k})
                    UNt{i,k} = pit*arvRates(:,i,k)*map_mean(PH{i,k})/S(i);
                end
        end
    end
end

% QNt(isnan(QNt))=0;
% UNt(isnan(UNt))=0;
% %XNt(isnan(XNt))=0;
% TNt(isnan(TNt))=0;

runtime = toc(Tstart);

if options.verbose > 0
    fprintf(1,'CTMC analysis completed in %f sec\n',runtime);
end
end