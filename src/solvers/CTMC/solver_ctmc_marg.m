function [Pnir,runtime,fname] = solver_ctmc_marg(qn, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.


M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
state = qn.state;
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
        PH{i,k} = Coxian(mu{i,k}, phi{i,k}).getRenewalProcess();
    end
end

myP = cell(K,K);
for k = 1:K
    for c = 1:K
        myP{k,c} = zeros(qn.nstations);
    end
end

for ist=1:qn.nstations
    for jst=1:qn.nstations
        for k = 1:K
            for c = 1:K
                % routing table for each class
                myP{k,c}(ist,jst) = rt((ist-1)*K+k,(jst-1)*K+c);
            end
        end
    end
end

[Q,SS,SSq,~,~,qn] = solver_ctmc(qn, options);
if options.keep
    fname = tempname;
    save([fname,'.mat'],'Q','SSq')
    fprintf(1,'CTMC generator and state space saved in: ');
    disp([fname, '.mat'])
end
pi = ctmc_solve(Q);
pi(pi<1e-14)=0;

statesz = [];
for ind=1:qn.nnodes
    if qn.isstateful(ind)
        isf = qn.nodeToStateful(ind);
        statesz(isf) = size(qn.space{isf},2);
    end
end
cstatesz = [0,cumsum(statesz)];
for ind=1:qn.nnodes
    if qn.isstateful(ind)
        isf = qn.nodeToStateful(ind);
        ist = qn.nodeToStation(ind);
        state_i = [zeros(1,size(qn.space{isf},2)-length(state{isf})),state{isf}];
        Pnir(ist) = sum(pi(findrows(SS(:,(cstatesz(isf)+1):(cstatesz(isf)+length(state_i))), state_i)));
    end
end

runtime = toc(Tstart);

if options.verbose > 0
    fprintf(1,'CTMC analysis completed in %f sec\n',runtime);
end
end