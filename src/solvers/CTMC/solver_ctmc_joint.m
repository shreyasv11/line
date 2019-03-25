function [Pnir,runtime,fname] = solver_ctmc_joint(qn, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
fname = '';
rt = qn.rt;
mu = qn.mu;
phi = qn.phi;

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

for i=1:qn.nstations
    for j=1:qn.nstations
        for k = 1:K
            for c = 1:K
                % routing table for each class
                myP{k,c}(i,j) = rt((i-1)*K+k,(j-1)*K+c);
            end
        end
    end
end

[Q,SS,~,~,~,qn] = solver_ctmc(qn, options);
if options.keep
    fname = tempname;
    save([fname,'.mat'],'Q','SSq')
    fprintf(1,'CTMC generator and state space saved in: ');
    disp([fname, '.mat'])
end
pi = ctmc_solve(Q);
pi(pi<1e-14)=0;

statevec = [];
state = qn.state;
for i=1:qn.nstations
    if qn.isstateful(i)
        isf = qn.nodeToStateful(i);
        state_i = [zeros(1,size(qn.space{isf},2)-length(state{isf})),state{isf}];
        statevec = [statevec, state_i];
    end
end
Pnir = pi(findrows(SS, statevec));

runtime = toc(Tstart);

if options.verbose > 0
    fprintf(1,'CTMC analysis completed in %f sec\n',runtime);
end
end