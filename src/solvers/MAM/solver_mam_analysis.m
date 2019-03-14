function [QN,UN,RN,TN,CN,XN,runtime] = solver_mam_analysis(qn, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes

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

[QN,UN,RN,TN,CN,XN] = solver_mam(qn, PH, options);

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;

runtime = toc(Tstart);

if options.verbose > 0
    fprintf(1,'MAM analysis completed in %f sec\n',runtime);
end
end