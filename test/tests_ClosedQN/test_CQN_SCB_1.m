% EXAMPLE_solver_fluid_analysis_1 exemplifies the use of LINE to analize CQN models 
% with Cox processing times. 
%
% Copyright (c) 2012-2018, Imperial College London 
% All rights reserved.

% CQN_SCB: synchronous calls with blocking

addpath(genpath('C:\Juan\line\branches\dev\src'))

M = 3;
K = 2; 

NK = [  5;
        80];
N = sum(NK(isfinite(NK)));

procTimes =  [  20   15;
                1    5];
think = 80*ones(1,K);
rates = [   1./think;
            1./procTimes];
       
phi = cell(M,K);
mu = cell(M,K);
phases = 1; % number of exp phases
for l = 1:M
    for k = 1:K
        mu{l,k} = ones(phases,1)*phases*rates(l,k); % accelerate rate
        phi{l,k} = [zeros(phases-1,1); 1]; % temination only at last phase
    end
end

S = [   -1; 
        4;
        4];

V = zeros(M, M, K);     % resources blocked (dim 2) when executing 
                        % jobs of each class (dim 3) in station (dim 1)

V(2,3,1) = 1; % class-1 jobs block 1 resource in station 3 when executing in station 2


sched = {SchedStrategy.INF;SchedStrategy.PS;SchedStrategy.PS}; 
P = [zeros(K)       eye(K)   zeros(K);
     [1 0;
      0 0]          zeros(K) [0 0;
                              0 1]; 
     [0 0;
      0 1]         zeros(K,2*K)];
chains = eye(K);
refNodes = ones(K,1);
nodeNames = {'delay'; 'proc1'; 'proc1'};
classnames = cell(K,1);
for j = 1:K
    classnames{j} = ['class',int2str(j)]; 
end

qn = EQNSCB(M, K, N, S, V, mu, phi, sched, P, NK, chains, refNodes, nodeNames, classnames);
    
max_iter = 1000;
delta_max = 0.01;
RT = 1;
RTrange = [0.01:0.01:0.99]'; 
verbose = 0;
options = struct();
options.iter_max = max_iter;
options.verbose = verbose;
options.iter_tol = delta_max;
[Qb, Ub, Rb, Xb, ~, RT_CDFb, ~] = solver_SCB_fluid_analysis(qn, [], [], [], RT, RTrange, options);
Qb
%Ub
R1b = sum(Rb(2:3,1))
R2b = sum(Rb(2:3,2))
figure
plot(RT_CDFb{1,1}, RT_CDFb{1,2},'bx'); hold on;
plot(RT_CDFb{2,1}, RT_CDFb{2,2},'rx'); hold on;



%% without blocking
options = struct();
options.iter_max = max_iter;
options.verbose = verbose;
options.iter_tol = delta_max;

[Q, U, R, X, ~, RT_CDF, ~] = solver_fluid_analysis(qn, [], [], [], RT, RTrange, options);
Q
%U
R1 = sum(R(2:3,1))
R2 = sum(R(2:3,2))

plot(RT_CDF{1,1}, RT_CDF{1,2},'b-'); hold on;
plot(RT_CDF{2,1}, RT_CDF{2,2},'r-'); hold off;
legend('Class 1 block', 'Class 2 block', 'Class 1', 'Class 2', 'Location', 'SouthEast')
xlabel('Response Time')
ylabel('CDF')
%title('Without blocking')

