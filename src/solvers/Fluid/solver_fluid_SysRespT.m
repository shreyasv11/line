function RTret = solver_fluid_sysrespt(qn, RTrange, options, completes)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.


iter_max = options.iter_max;
verbose = options.verbose;
y0 = options.init_sol;

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
N = qn.nclosedjobs;    %population
Lambda = qn.mu;
Pi = qn.phi;
rt = qn.rt;
S = qn.nservers;

for j = 1:M
    %Set number of servers in delay station = population
    if isinf(S(j))
        S(j) = N;
    end
end

%% initialization

phases = zeros(M,K);
for j = 1:M
    for k = 1:K
        %phases(i,k,e) = length(Lambda{e,i,k});
        phases(j,k) = length(Lambda{j,k});
    end
end
slowrate = zeros(M,K);
for j = 1:M
    for k = 1:K
        slowrate(j,k) = Inf;
        slowrate(j,k) = min(slowrate(j,k),min(Lambda{j,k}(:))); %service completion (exit) rates in each phase
    end
end

%% response time analysis - starting from fixed point found
stiff = 1;
chains = qn.chains;
nChains = size(chains,1);

RT = cell(nChains,2);
for k = 1:nChains %once for each chain
    idxClassesInChain = find(chains(k,:)==1);
    refStat = qn.refstat(idxClassesInChain(1));
    Knew = K + sum(chains(k,:),2);
    numTranClasses = Knew - K;
    idxTranCl = zeros(1,K); % indices of the transient class corresponding to each class in the original model for class k
    idxTranCl(chains(k,:)==1) =  K+1:Knew;
    newLambda = cell(M,Knew);
    newPi = cell(M,Knew);
    new_rt = zeros(M*Knew, M*Knew);
    
    % service rates
    newLambda(:,1:K) = Lambda(:,:);
    for l = 1:numTranClasses
        newLambda(:,K+l) = Lambda(:,idxClassesInChain(l));
    end
    
    % completion probabilities
    newPi(:,1:K) = Pi(:,:);
    for l = 1:numTranClasses
        newPi(:,K+l) = Pi(:,idxClassesInChain(l));
    end
    
    % routing/switching probabilities
    % among basic classes
    for l = 1:K
        for m = 1:K
            new_rt(l:Knew:end,m:Knew:end) = rt(l:K:end,m:K:end);
        end
    end
    
    % copy probabilities from the original to the transient classes (forward)
    for l = 1:numTranClasses
        for m = 1:numTranClasses
            if sum(sum(rt(idxClassesInChain(l):K:end,idxClassesInChain(m):K:end))) > 0
                new_rt(K+l:Knew:end,K+m:Knew:end) = rt(idxClassesInChain(l):K:end,idxClassesInChain(m):K:end);
            end
        end   
    end
    
    %phases of transient classes
    newPhases = zeros(M,Knew);
    newPhases(:,1:K) = phases;
    for l = 1:numTranClasses
        newPhases(:,K+l) = phases(:,idxClassesInChain(l));
    end
    
    % identify classes in chain that complete
    completingClassesInChain = find(completes)';        
    
    %determine final classes (leaves in the class graph)
    for s = completingClassesInChain' % for each completing class
        %routing matrix from a transient class that completes is diverted back into the original classes
        for l = idxClassesInChain            
            rt_ls = rt(l:K:end,s:K:end);               
            feedsRefStat = find(rt_ls(:,refStat)>0)'; % stations with transitions class l -> class s to ref node
            for j = feedsRefStat
                % return fluid to original class
                new_rt((j-1)*Knew+idxTranCl(l), (refStat-1)*Knew+s) = rt((j-1)*K+l, (refStat-1)*K+s);                
                % delete corresponding transition among transient classes
                new_rt((j-1)*Knew+idxTranCl(l), (refStat-1)*Knew+idxTranCl(s)) = 0;                
            end
        end
    end
    
    %setup the ODEs for the new QN
    [newOde_h, ~] = solver_fluid_odes(N, reshape({newLambda{:,:}},M,Knew), reshape({newPi{:,:}},M,Knew), new_rt, S, qn.sched);
        
    stationsAfterRefStat = []; % list of output stations when moving out of ref node
    for s = idxClassesInChain
        for l = idxClassesInChain
            for i=1:M
                if rt((refStat-1)*K + s, (i-1)*K + l) > 0 && ismember(l, completingClassesInChain)
                    stationsAfterRefStat = [stationsAfterRefStat, i];
                end
            end
        end
    end
    
    newY0 = zeros(1, sum(sum(newPhases(:,:))));
    newFluid = 0;
    for j = 1:M
        for l = 1:K
            idxNew_jl = sum(sum(newPhases(1:j-1,:))) + sum(newPhases(j,1:l-1));
            idxNew_jt = sum(sum(newPhases(1:j-1,:))) + sum(newPhases(j,1:idxTranCl(l)-1));            
            idx_jl = sum(sum(phases(1:j-1,:))) + sum(phases(j,1:l-1));
            if ismember(j,stationsAfterRefStat) && ismember(l,idxClassesInChain) && ismember(l, completingClassesInChain)
                newY0( idxNew_jt + 1: idxNew_jt + newPhases(j,idxTranCl(l))  ) = y0(idx_jl+1:idx_jl + phases(j,l)); 
                newFluid = newFluid + sum(y0(idx_jl+1:idx_jl + phases(j,l)));
            else % leave mass as it is
                newY0( idxNew_jl + 1: idxNew_jl + newPhases(j,l)  ) = y0(idx_jl+1:idx_jl + phases(j,l));
            end
        end
    end
    y0
    newY0
    
    iters = 0;
    iters = iters + 1;
    RTtemp = cell (1,2);
    nonZeroRates = slowrate(:);
    nonZeroRates = nonZeroRates( nonZeroRates >0 );
    T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate
    
    %indices new classes in all stations but delay
    idxN = [];
    for j = 1:M
        if j ~= refStat
            idxN = [idxN sum(sum(newPhases(1:j-1,: ) )) + sum(newPhases(j,1:K)) + [1:sum(newPhases(j,K+1:Knew))] ]; %works for
        end
    end
    
    %% ODE analysis
    fullt = [];
    fully = [];
    iter = 1;
    finished = 0;
    tref = 0;
    while iter <= iter_max && finished == 0
        % solve ode - yt_e is the transient solution in stage e
        opt = odeset('AbsTol', options.tol, 'RelTol', options.tol, 'NonNegative', 1:length(newY0),'Events',@events);
        if options.stiff
            if options.tol < 1e-3
                [t, yt_e] = feval(options.odesolvers.accurateStiffOdeSolver, newOde_h, [0 T], newY0, opt);
            else
                [t, yt_e] = feval(options.odesolvers.fastStiffOdeSolver, newOde_h, [0 T], newY0, opt);
            end
        else
            if options.tol < 1e-3
                [t, yt_e] = feval(options.odesolvers.accurateOdeSolver, newOde_h, [0 T], newY0, opt);
            else
                opt = odeset('AbsTol', 1e-6, 'RelTol', 1e-3,'Events',@events);
                [t, yt_e] = feval(options.odesolvers.fastOdeSolver, newOde_h, [0 T], newY0, opt);
            end
        end
        iter = iter + 1;
        fullt = [fullt; t+tref];
        fully = [fully; yt_e];
        if sum(yt_e(end,idxN )) < 10e-10
            finished = 1;
        end
        tref = tref + t(end);
        newY0 = yt_e(end,:);
    end
    % retrieve response time CDF for class k
    RT{k,1} = fullt;
    if newFluid > 0
        RT{k,2} = 1 - sum(fully(:,idxN ),2)/newFluid;
    else
        RT{k,2} = ones(size(fullt));
    end
    if iter > iter_max
        warning('Maximum number of iterations reached when computing the response time distribution.\n Response time distributions may be affected numerically');
    end
    if verbose > 1
        a = ( RT{k,2}(1:end-1) + RT{k,2}(2:end) )/2;
        meanRT = sum(diff(RT{k,1}).*(1-a));
        disp(['Mean response time class ', int2str(k),': ', num2str(meanRT)]);
    end
    % determine the value of the  percentiles requested (RTrange)
    if ~isempty(RTrange) && RTrange(1) >=0 && RTrange(end) <=1
        if newFluid > 0
            percRT = interp1q(RT{k,2}, RT{k,1}, RTrange);
        else
            percRT = zeros(size(RTrange));
        end
        RT{k,1} = percRT;
        RT{k,2} = RTrange;
    end
end

RTret = {};
for k=1:size(RT,1)
    RTret{k} = [RT{k,2},RT{k,1}];
end
return

    function [value,isterminal,direction] = events(t,y)
        value = sum(y(idxN));
        isterminal = 1;
        direction = 0;
    end

end
