function [QN,UN,RN,TN,CN,XN,InfGen,StateSpace,StateSpaceAggr,EventFiltration,runtime,fname] = solver_ctmc_analysis(qn, options)
% [QN,UN,RN,TN,CN,XN,INFGEN,STATESPACE,STATESPACEAGGR,EVENTFILTRATION,RUNTIME,FNAME] = SOLVER_CTMC_ANALYSIS(QN, OPTIONS)
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
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

[InfGen,StateSpace,StateSpaceAggr,EventFiltration,arvRates,depRates,qn] = solver_ctmc(qn, options); % qn is updated with the state space

if options.keep
    fname = tempname;
    save([fname,'.mat'],'InfGen','StateSpace','StateSpaceAggr','EventFiltration')
    fprintf(1,'CTMC infinitesimal generator and state space saved in: ');
    disp([fname, '.mat'])
end

pi = ctmc_solve(InfGen, options);
pi(pi<1e-14)=0;
pi = pi/sum(pi);

XN = NaN*zeros(1,K);
UN = NaN*zeros(M,K);
QN = NaN*zeros(M,K);
RN = NaN*zeros(M,K);
TN = NaN*zeros(M,K);
CN = NaN*zeros(1,K);

for k=1:K
    refsf = qn.stationToStateful(qn.refstat(k));
    XN(k) = pi*arvRates(:,refsf,k);
    for i=1:M
        isf = qn.stationToStateful(i);
        TN(i,k) = pi*depRates(:,isf,k);
        QN(i,k) = pi*StateSpaceAggr(:,(i-1)*K+k);
        switch sched{i}
            case SchedStrategy.INF
                UN(i,k) = QN(i,k);
            otherwise
                if ~isempty(PH{i,k})
                    UN(i,k) = pi*arvRates(:,i,k)*map_mean(PH{i,k})/S(i);
                end
        end
    end
end

for k=1:K
    for i=1:M
        if TN(i,k)>0
            RN(i,k) = QN(i,k)./TN(i,k);
        else
            RN(i,k)=0;
        end
    end
    CN(k) = NK(k)./XN(k);
end

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;

runtime = toc(Tstart);

%if options.verbose > 0
%    fprintf(1,'CTMC analysis completed in %f sec\n',runtime);
%end
end
