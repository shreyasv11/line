function RTret = solver_fluid_passage_time(qn, options)
% RTRET = SOLVER_FLUID_PASSAGE_TIME(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

iter_max = options.iter_max;
verbose = options.verbose;
y0 = options.init_sol;

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes
N = qn.nclosedjobs;    %population
Lambda = qn.mu;
Pi = qn.phi;
PH = qn.ph;
rt = qn.rt;
S = qn.nservers;

for j = 1:M
    %Set number of servers in delay station = population
    if isinf(S(j))
        S(j) = N;
    end
end

%% initialization

% phases = zeros(M,K);
% for j = 1:M
%     for k = 1:K
%         %phases(i,k,e) = length(Lambda{e,i,k});
%         phases(j,k) = length(Lambda{j,k});
%     end
% end
phases = qn.phases;
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

RT = [];
for i = 1:qn.nstations
    for k = 1:nChains %once for each chain
        idxClassesInChain = find(chains(k,:)==1);
        for c = idxClassesInChain
            Knew = K + 1;
            numTranClasses = Knew - K;
            idxTranCl = zeros(1,K); % indices of the transient class corresponding to each class in the original model for class k
            idxTranCl(chains(k,:)==1) =  K+1:Knew;
            newLambda = cell(M,Knew);
            newPi = cell(M,Knew);
            new_rt = zeros(M*Knew, M*Knew);
            newPH = PH;
            
            for j=1:qn.nstations
                % service rates
                newLambda(j,1:K) = Lambda(j,:);
                newLambda(j,K+1) = Lambda(j,c);
                
                % completion probabilities
                newPi(j,1:K) = Pi(j,:);
                newPi(j,K+1) = Pi(j,c);
                
                % phd distribution
                for r=1:nChains
                    newPH{j,r} = PH{j,r};
                end
                newPH{j,K+1} = PH{j,c};
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
                    if sum(sum(rt(c:K:end,idxClassesInChain(m):K:end))) > 0
                        new_rt(K+l:Knew:end,K+m:Knew:end) = rt(c:K:end,idxClassesInChain(m):K:end);
                    end
                end
            end
            
            %phases of transient classes
            newPhases = zeros(M,Knew);
            newPhases(:,1:K) = phases;
            newPhases(:,K+1) = phases(:,c);
            
            % identify classes in chain that complete
            completingClassesInChain = c;
            
            %determine final classes (leaves in the class graph)
            for s = completingClassesInChain' % for each completing class
                %routing matrix from a transient class that completes is diverted back into the original classes
                for l = idxClassesInChain
                    for j = 1:qn.nstations
                        % return fluid to original class
                        new_rt((i-1)*Knew+idxTranCl(c), (j-1)*Knew+l) = rt((i-1)*K+c, (j-1)*K+l);
                        % delete corresponding transition among transient classes
                        new_rt((i-1)*Knew+idxTranCl(c), (j-1)*Knew+idxTranCl(l)) = 0;
                    end
                end
            end
            
            %setup the ODEs for the new QN
            [newOde_h, ~] = solver_fluid_odes(N, reshape({newLambda{:,:}},M,Knew), reshape({newPi{:,:}},M,Knew), newPH, new_rt, S, qn.sched, qn.schedparam, options);
            
            newY0 = zeros(1, sum(sum(newPhases(:,:))));
            newFluid = 0;
            for j = 1:qn.nstations
                for l = 1:qn.nclasses
                    idxNew_jl = sum(sum(newPhases(1:j-1,:))) + sum(newPhases(j,1:l-1));
                    idxNew_jt = sum(sum(newPhases(1:j-1,:))) + sum(newPhases(j,1:idxTranCl(l)-1));
                    idx_jl = sum(sum(phases(1:j-1,:))) + sum(phases(j,1:l-1));
                    if i == j && l==c
                        newY0( idxNew_jt + 1 ) = sum(y0(idx_jl+1:idx_jl + phases(j,l))); % mass in phases all moved back into phase 1
                        newFluid = newFluid + sum(y0(idx_jl+1:idx_jl + phases(j,l)));
                    else % leave mass as it is
                        newY0( idxNew_jl + 1: idxNew_jl + newPhases(j,l)  ) = y0(idx_jl+1:idx_jl + phases(j,l));
                    end
                end
            end
            
            iters = 0;
            iters = iters + 1;
            nonZeroRates = slowrate(:);
            nonZeroRates = nonZeroRates( nonZeroRates >0 );
            T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with slowest exit rate
            
            %indices new classes in all stations but delay
            idxN = [];
            for j = i
                idxN = [idxN sum(sum(newPhases(1:j-1,: ) )) + sum(newPhases(j,1:K)) + [1:sum(newPhases(j,K+1:Knew))] ]; %works for
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
            RT{i,c,1} = fullt;
            if newFluid > 0
                RT{i,c,2} = 1 - sum(fully(:,idxN ),2)/newFluid;
            else
                RT{i,c,2} = ones(size(fullt));
            end
            if iter > iter_max
                warning('Maximum number of iterations reached when computing the response time distribution. Response time distributions may be inaccurate. Increase option.iter_max (currently at %s).',num2str(iter_max));
            end
        end
    end
end

RTret = {};
for i=1:qn.nstations
    for c=1:qn.nclasses
        RTret{i,c} = [RT{i,c,2},RT{i,c,1}];
    end
end
return

    function [value,isterminal,direction] = events(t,y)
        % [VALUE,ISTERMINAL,DIRECTION] = EVENTS(T,Y)
        
        value = sum(y(idxN));
        isterminal = 1;
        direction = 0;
    end

end
