function [ode_h,q_indices] = solver_fluid_odes(N, Mu, Phi, P, S, sched, schedparam)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

M = length(S);    % number of stations
K = size(Mu,2);   % number of classes
w = ones(M,K);

match = zeros(M,K); % indicates whether a class is served at a station
for i = 1:M
    for c = 1:K
        %match(i,c) = sum( P(:,(i-1)*K+c) ) > 0;
        %changed to consider rows instead of colums, for response time
        %analysis (first articial class never returns to delay node)
        match(i,c) = sum( P((i-1)*K+c,:) ) > 0;
    end
end

q_indices = zeros(M,K);
Kic = zeros(M,K);
cumsum = 1;
for i = 1 : M
    for c = 1:K
        q_indices(i,c) = cumsum;
        if isnan(Mu{i,c})
            numphases = 0;
        else
            numphases = length(Mu{i,c});
        end
        Kic(i,c) = numphases;
        cumsum = cumsum + numphases;
    end
end
nx = cumsum - 1;

% to speed up convert sched strings in numerical values
strategy = zeros(1,M);
for i = 1 : M
    switch sched{i} % source
        case SchedStrategy.EXT
            strategy(i) = 0;
        case SchedStrategy.INF
            strategy(i) = 1;
        case {SchedStrategy.PS, SchedStrategy.FCFS}
            strategy(i) = 2;
        case SchedStrategy.DPS
            strategy(i) = 3;
            w(i,:) = schedparam(i,:); % to be implemented
    end
end

% determine all the jumps, and saves them for later use
all_jumps = ode_jumps_new(M, K, match, q_indices, P, Kic, strategy);

% determines a vector with the fixed part of the rates,
% and defines the indexes that correspond to the events that occur
[rateBase, eventIdx] = getRateBase(Phi,Mu,M, K, match, q_indices, P, Kic, strategy, all_jumps);

%% define ODE system to be returned
ode_h = @(t,x) all_jumps*ode_rates_new(x, M, K, q_indices, Kic, S, w, strategy, rateBase, eventIdx);
end

