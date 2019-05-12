function [t,pit,QNt,UNt,RNt,TNt,CNt,XNt,InfGen,StateSpace,StateSpaceAggr,EventFiltration,runtime,fname] = solver_ctmc_transient_analysis(qn, options)
% [T,PIT,QNT,UNT,RNT,TNT,CNT,XNT,INFGEN,STATESPACE,STATESPACEAGGR,EVENTFILTRATION,RUNTIME,FNAME] = SOLVER_CTMC_TRANSIENT_ANALYSIS(QN, OPTIONS)
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

RNt=[]; CNt=[];  XNt=[];

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
fname = '';
rt = qn.rt;
S = qn.nservers;
NK = qn.njobs';  % initial population per class
sched = qn.sched;

Tstart = tic;

PH = qn.proc;

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

[InfGen,StateSpace,StateSpaceAggr,EventFiltration,~,depRates,qn] = solver_ctmc(qn, options); % qn is updated with the state space


if options.keep
    fname = tempname;
    save([fname,'.mat'],'InfGen','StateSpace','StateSpaceAggr','EventFiltration')
    fprintf(1,'CTMC infinitesimal generator and state space saved in: ');
    disp([fname, '.mat'])
end

state = [];
for i=1:qn.nnodes
    if qn.isstateful(i)
        isf = qn.nodeToStateful(i);
        state = [state,zeros(1,size(qn.space{isf},2)-length(qn.state{isf})),qn.state{isf}];
    end
end
pi0 = zeros(1,length(InfGen));
pi0(matchrow(StateSpace,state)) = 1; % find initial state and set it to probability 1

%if options.timespan(1) == options.timespan(2)
%    pit = ctmc_uniformization(pi0,Q,options.timespan(1));
%    t = options.timespan(1);
%else
[pit,t] = ctmc_transient(InfGen,pi0,options.timespan(1),options.timespan(2),options.stiff);
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
        QNt{i,k} = pit*StateSpaceAggr(:,(i-1)*K+k);
        switch sched{i}
            case SchedStrategy.INF
                UNt{i,k} = QNt{i,k};
            case {SchedStrategy.FCFS, SchedStrategy.HOL, SchedStrategy.RAND, SchedStrategy.SEPT, SchedStrategy.LEPT, SchedStrategy.SJF}
                if ~isempty(PH{i,k})
                    UNt{i,k} = pit*min(StateSpaceAggr(:,(i-1)*K+k),S(i))/S(i);
                end
            case SchedStrategy.PS
                nik = S(i)* StateSpaceAggr(:,(i-1)*K+k) ./ sum(StateSpaceAggr(:,((i-1)*K+1):(i*K)),2);
                nik(isnan(nik))=0;
                UNt{i,k} = pit*nik;
            case SchedStrategy.DPS
                w = qn.schedparam(i,:);
                nik = S(i) * w(k) * StateSpaceAggr(:,(i-1)*K+k) ./ sum(repmat(w,size(StateSpaceAggr,1),1).*StateSpaceAggr(:,((i-1)*K+1):(i*K)),2);
                nik(isnan(nik))=0;
                UNt{i,k} = pit*nik;
            otherwise
                if ~isempty(PH{i,k})
                    ind = qn.stationToNode(i);
                    warning('Transient utilization not support yet for station %s, returning an approximation.',qn.nodenames{ind});
                    UNt{i,k} = pit*min(StateSpaceAggr(:,(i-1)*K+k),S(i))/S(i);
                end
        end
    end
end
runtime = toc(Tstart);

if options.verbose > 0
    fprintf(1,'CTMC analysis completed in %f sec\n',runtime);
end
end
