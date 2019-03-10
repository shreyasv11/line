function [XN,UN,QN,RN,TN,CN]=solver_ssa_analysis_spmd(laboptions, qn, qnc, PH)
M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes

mu = qn.mu;
phi = qn.phi;
S = qn.nservers;
NK = qn.njobs';  % initial population per class
sched = qn.sched;
spmd
    laboptions.samples = ceil(laboptions.samples / numlabs);
    laboptions.verbose = false;
    if strcmp(laboptions.method, 'para')
        [pi,SSq,arvRates,depRates] = solver_ssa(qnc, laboptions);
        qn.space = qnc.space;
    elseif strcmp(laboptions.method, 'para.hash')
        [pi,SSq,arvRates,depRates] = solver_ssa_hashed(qnc, laboptions);
        qn.space = qnc.space;
    end
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
            QN(i,k) = pi*SSq(:,(i-1)*K+k);
            switch qn.sched{i}
                case SchedStrategy.INF
                    UN(i,k) = QN(i,k);
                otherwise
                    % we use Little's law, otherwise there are issues in
                    % estimating the fraction of time assigned to class k (to
                    % recheck)
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
                RN(i,k) = 0;
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
end

nLabs = length(QN);
QN = cellsum(QN)/nLabs;
UN = cellsum(UN)/nLabs;
RN = cellsum(RN)/nLabs;
TN = cellsum(TN)/nLabs;
CN = cellsum(CN)/nLabs;
XN = cellsum(XN)/nLabs;
end
