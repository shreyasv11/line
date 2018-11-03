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

% THIS PART TO BE KEPT AS IT ALLOWS TO MAKE RATES STATE-DEPENDENT
% function xj = get_index(j,k)
%     % n is the state vector
%     % j is the queue station index
%     % k is the class index
%     % RETURNS THE INDEX of the queue-length element xi! % in the state description
%     xj = 1;
%     for z = 1 : (j-1)
%         for y = 1:K
%             xj = xj + Kic(z,y);
%         end
%     end
%     for y = 1:k-1
%         xj = xj + Kic(j,y);
%     end
%
% end
%
% function rates = ode_rates(x)
%     rates = [];
%     n = zeros(1,M); % total number of jobs in each station
%     for i = 1:M
%         for c = 1:K
%             xic = q_indices(i,c);
%             n(i) = n(i) + sum( x(xic:xic+Kic(i,c)-1 ) );
%         end
%         if S(i) == sum(N)
%             n(i) = 1;
%         end
%     end
%
%
%
%     for i = 1 : M           %transition rates for departures from any station to any other station
%         for c = 1:K         %considers only transitions from the first service phase (enough for exp servers)
%             if match(i,c)>0
%             xic = q_indices(i,c);
%             for j = 1 : M
%                 for l = 1:K
%                     if P((i-1)*K+c,(j-1)*K+l) > 0
%                     for k = 1:Kic(i,c)
%                         %pure ps + fcfs correction
%                         if x(xic+k-1) > 0 && n(i) > S(i)
%                             rates = [rates; Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k) * x(xic+k-1)/n(i) * S(i);]; % f_k^{dep}
%                         elseif x(xic+k-1) > 0
%                             rates = [rates; Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k) * x(xic+k-1);]; % f_k^{dep}
%                         else
%                             rates = [rates; 0;]; % f_k^{dep}
%                         end
%                     end
%                     end
%                 end
%             end
%             end
%         end
%     end
%
%     for i = 1 : M           %transition rates for "next service phase" (phases 2...)
%         for c = 1:K
%             if match(i,c)>0
%             xic = q_indices(i,c);
%             for k = 1 : (Kic(i,c) - 1)
%                 if x(xic+k-1) > 0
%                     rates = [rates; (1-Phi{i,c}(k))*Mu{i,c}(k)*x(xic+k-1)/n(i)];
%                 else
%                     rates = [rates; 0 ]
%                 end
%             end
%             end
%         end
%     end
%
% end
%
% function d = ode_jumps(x)
%     d = [];         %returns state changes triggered by all the events
%     for i = 1 : M   %state changes from departures in service phases 2...
%         for c = 1:K
%             if match(i,c)>0
%             xic = q_indices(i,c);
%             for j = 1 : M
%                 for l = 1:K
%                     if P((i-1)*K+c,(j-1)*K+l) > 0
%                     xjl = q_indices(j,l);
%                     for k = 1 : Kic(i,c)
%                         jump = zeros(length(x),1);
%                         jump(xic) = jump(xic) - 1; %type c in stat i completes service
%                         jump(xjl) = jump(xjl) + 1; %type c job starts in stat j
%                         d = [d jump;];
%                     end
%                     end
%                 end
%             end
%             end
%         end
%     end
%
%     for i = 1 : M   %state changes from "next service phase" transition in phases 2...
%         for c = 1:K
%             if match(i,c)>0
%             xic = q_indices(i,c);
%             for k = 1 : (Kic(i,c) - 1)
%                 jump = zeros(length(x),1);
%                 jump(xic+k-1) = jump(xic+k-1) - 1;
%                 jump(xic+k) = jump(xic+k) + 1;
%                 d = [d jump;];
%             end
%             end
%         end
%     end
% end

    function [rateBase, eventIdx] = getRateBase()
        rateBase = zeros(size(all_jumps,2),1);
        eventIdx = zeros(size(all_jumps,2),1);
        rateIdx = 0;
        for i = 1 : M   %state changes from departures in service phases 2...
            for c = 1:K
                if match(i,c)>0
                    for j = 1 : M
                        for l = 1:K
                            if P((i-1)*K+c,(j-1)*K+l) > 0
                                for k = 1 : Kic(i,c)
                                    rateIdx = rateIdx + 1;
                                    rateBase(rateIdx) = Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k);
                                    eventIdx(rateIdx) = q_indices(i,c) + k - 1;
                                end
                            end
                        end
                    end
                end
            end
        end
        
        for i = 1 : M   %state changes from "next service phase" transition in phases 2...
            for c = 1:K
                if match(i,c)>0
                    for k = 1 : (Kic(i,c) - 1)
                        rateIdx = rateIdx + 1;
                        rateBase(rateIdx) = (1-Phi{i,c}(k))*Mu{i,c}(k);
                        eventIdx(rateIdx) = q_indices(i,c) + k - 1;
                    end
                end
            end
        end
    end

    function rates = ode_rates_new(x)
        %rates = zeros(size(rateBase));
        %        rates = zeros(nx,1);
        rates = x;
        % build variable rate vector
        for i = 1:M
            switch strategy(i) % source
                case 0  %EXT
                    for k=1:K
                        idxIni = q_indices(i,k);
                        idxEnd = q_indices(i,k) + Kic(i,k) - 1;
                        %                        rates(idxIni:idxEnd) = [1-sum(x(idxIni+1:idxEnd)),x(idxIni+1:idxEnd)];
                        rates(idxIni) = 1-sum(x(idxIni+1:idxEnd)); % not needed for idxIni+1:idxEnd as rates is initiliazed equal to x
                    end
                case 1  %INF
                    idxIni = q_indices(i,1);
                    idxEnd = q_indices(i,K) + Kic(i,K) - 1;
                    %rates(idxIni:idxEnd) = x(idxIni:idxEnd); % not needed as rates is initiliazed equal to x
                case 2  %PS
                    idxIni = q_indices(i,1);
                    idxEnd = q_indices(i,K) + Kic(i,K) - 1;
                    ni = sum( x(idxIni:idxEnd) );
                    if ni > 0 && min(ni,S(i)) == S(i) % otherwise simplifies
                        %                        rates(idxIni:idxEnd) = x(idxIni:idxEnd)/n * min(n,S(i));
                        rates(idxIni:idxEnd) = x(idxIni:idxEnd)/ni * S(i);
                    end
                case 3  %DPS
                    w(i,:) = w(i,:)/sum(w(i,:));
                    %ni = 1e-2;
                    ni = mean(w(i,:));
                    for k=1:K
                        idxIni = q_indices(i,k);
                        idxEnd = q_indices(i,k) + Kic(i,k) - 1;
                        ni = ni + sum( w(i,k)*x(idxIni:idxEnd) );
                    end
                    for k=1:K
                        idxIni = q_indices(i,k);
                        idxEnd = q_indices(i,k) + Kic(i,k) - 1;
                        rates(idxIni:idxEnd) = w(i,k)*x(idxIni:idxEnd)/ni * S(i); % not needed for idxIni+1:idxEnd as rates is initiliazed equal to x
                    end
            end
        end
        rates = rates(eventIdx);
        %build effective rate vector
        rates = rateBase.*rates;
    end

    function jumps = ode_jumps_new()
        jumps = []; %returns state changes triggered by all the events
        for i = 1 : M   %state changes from departures in service phases 2...
            for c = 1:K
                if match(i,c)>0
                    xic = q_indices(i,c); % index of  x_ic
                    for j = 1 : M
                        for l = 1:K
                            if P((i-1)*K+c,(j-1)*K+l) > 0
                                xjl = q_indices(j,l); % index of x_jl
                                for k = 1 : Kic(i,c)
                                    jump = zeros( sum(sum(Kic)), 1 );
                                    switch strategy(i)
                                        case 0 %EXT
                                            jump(xjl) = jump(xjl) + 1; %type c job starts in stat j
                                            jump(xic+k-1) = jump(xic+k-1) - 1; %type c in stat i completes service
                                            %                                            jump(xic) = jump(xic) + 1; %type c in stat i completes service
                                            jumps = [jumps jump;];
                                        otherwise
                                            jump(xic+k-1) = jump(xic+k-1) - 1; %type c in stat i completes service
                                            jump(xjl) = jump(xjl) + 1; %type c job starts in stat j
                                            jumps = [jumps jump;];
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        for i = 1 : M   %state changes from "next service phase" transition in phases 2...
            for c = 1:K
                if match(i,c)>0
                    xic = q_indices(i,c);
                    for k = 1 : (Kic(i,c) - 1)
                        jump = zeros( sum(sum(Kic)), 1 );
                        jump(xic+k-1) = jump(xic+k-1) - 1;
                        jump(xic+k) = jump(xic+k) + 1;
                        jumps = [jumps jump;];
                    end
                end
            end
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
all_jumps = ode_jumps_new();

% determines a vector with the fixed part of the rates,
% and defines the indexes that correspond to the events that occur
[rateBase, eventIdx] = getRateBase();

%% define ODE system to be returned
    function diff = ode(t,x)
        diff = all_jumps*ode_rates_new(x); %rate of change in state x
    end

ode_h = @ode;
%all_jumps'
end
