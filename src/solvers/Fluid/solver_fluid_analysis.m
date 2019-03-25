function [Qfull, Ufull, Rfull, Tfull, Cfull, Xfull, t, Qfull_t, Ufull_t, Tfull_t, lastSolution] = solver_fluid_analysis(qn, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

Cfull=[]; Xfull=[];

M = qn.nstations;
K = qn.nclasses;
mu = qn.mu;
phi = qn.phi;
S = qn.nservers;
SCV = qn.scv;

PH=cell(M,K);
for i=1:M
    for k=1:K
        if length(mu{i,k})==1
            PH{i,k} = map_exponential(1/mu{i,k});
            rates0(i,k) = mu{i,k};
            phases(i,k) = 1;
        else
            PH{i,k} = Coxian(mu{i,k}, phi{i,k}).getRenewalProcess();
            rates0(i,k) = map_lambda(PH{i,k});
            phases(i,k) = length(PH{i,k}{1});
        end
    end
end

if isempty(options.init_sol)
    options.init_sol = solver_fluid_initsol(qn, options);
end

outer_iters = 1;
outer_runtime = tic;
[Qfull, Ufull, Rfull, Tfull, ymean, Qfull_t, Ufull_t, Tfull_t, ~, t] = solver_fluid_analysis_inner(qn, options);
outer_runtime = toc(outer_runtime);
phases_last = phases;
if findstring(qn.sched, SchedStrategy.FCFS) ~= -1 % if there are FCFS stations
    rates = rates0;
    iter = 0;
    eta_1 = zeros(1,M);
    eta = Inf*ones(1,M);
    tol = 1e-2;
    
    while max(abs(1-eta./eta_1)) > tol && iter <= options.iter_max
        iter = iter + 1;
        eta_1 = eta;        
        eta= zeros(1,M);
        cs = ones(M,1);
        for i=1:M
            B(i) = min(sum(Qfull(i,:)),S(i)); % number of busy servers
        end        
        for i=1:M
            sd = rates0(i,:)>0;
            Ufull(i,sd) = Tfull(i,sd) ./ rates0(i,sd);
            switch qn.sched{i}
                case SchedStrategy.FCFS
                    sd = rates0(i,:)>0;
                    if range(rates0(i,sd))>0 % check if non-product-form
                        rho(i) = sum(Ufull(i,sd))/S(i); % true utilization of each server
                        ca = 0;
                        for j=1:M
                            for r=1:K
                                if rates0(j,r)>0
                                    for s=1:K
                                        if rates0(i,s)>0
                                            pji_rs = qn.rt((i-1)*qn.nclasses + r, (j-1)*qn.nclasses + s);
                                            ca = ca + (SCV(j,r))*Tfull(j,r)*pji_rs/sum(Tfull(i,sd));
                                        end
                                    end
                                end
                            end
                        end
                        cs(i) = (SCV(i,sd)*Tfull(i,sd)')/sum(Tfull(i,sd));
                        eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca*rho(i)));
                        %eta(i) = rho(i);
                        % dimensionally a utilization, (diffusion approximation, Kobayashi JACM)
                    end
            end
        end
        
        for i=1:M
            switch qn.sched{i}
                case SchedStrategy.FCFS
                    sd = rates0(i,:)>0;
                    if range(rates0(i,sd))>0 % check if non-product-form
                        for k=1:K
                            if sum(Qfull(i,:)) < S(i)
                                if Ufull(i,k) > 0
                                    rates(i,k) = rates0(i,k);
                                end
                            else
                                if rates(i,k) > 0
                                    rates(i,k) = sum(Tfull(i,rates(i,:)>0))/(eta(i)*S(i));
                                end
                            end
                        end
                    end
            end
        end
        rates(isnan(rates))=0;
        
        for i=1:M
            switch qn.sched{i}
                case SchedStrategy.FCFS
                    for k=1:K
                        if rates(i,k)>0
                            PH{i,k} = map_scale(PH{i,k},1/rates(i,k));
                            [muik,phiik] = Coxian.fitMeanAndSCV(map_mean(PH{i,k}), SCV(i,k));
                            %[muik,phiik] = Coxian.fitMeanAndSCV(map_mean(PH{i,k}), 1); % replace with an exponential
                            % we now handle the case that due to either numerical issues
                            % or different relationship between scv and mean the size of
                            % the phase-type representation has changed
                            phases(i,k) = length(muik);
                            if phases(i,k) ~= phases_last(i,k) % if number of phases changed
                                % before we update qn we adjust the initial state
                                isf = qn.stationToStateful(i);
                                [~, nir, sir] = State.toMarginal(qn, i, qn.state{isf}, options);
                            end
                            %if any(muik > 0.01+ qn.mu{i,k} * rates(i,k) / rates0(i,k))
                            %    keyboard
                            %end
                            qn.mu{i,k} = muik;
                            qn.phi{i,k} = phiik;
                            qn.phases = phases;
                            if phases(i,k) ~= phases_last(i,k)
                                isf = qn.stationToStateful(i);
                                % we now initialize the new service process
                                qn.state{isf} = State.fromMarginalAndStarted(qn, i, nir, sir, options);
                                qn.state{isf} = qn.state{isf}(1,:); % pick one as the marginals won't change
                            end
                        end
                    end
            end
        end
        
        options.init_sol = ymean{end}(:);
        if norm(phases_last-phases)>0 % If there is a change of phases reset
            options.init_sol = solver_fluid_initsol(qn);
        end
        qn.phases = phases;
        [Qfull, Ufull, ~, Tfull, ymean, ~, ~, ~, ~, ~, inner_iters, inner_runtime] = solver_fluid_analysis_inner(qn, options);
        phases_last = phases;
        outer_iters = outer_iters + inner_iters;
        outer_runtime = outer_runtime + inner_runtime;
    end % FCFS iteration ends here
    % The FCFS iteration reinitializes at the solution of the last
    % iterative step. We now have converged in the substitution of the
    % model parameters and we rerun everything from the true initial point
    % so that we get the correct transient.
    options.init_sol = solver_fluid_initsol(qn, options);
    [Qfull, Ufull, Rfull, Tfull, ymean, Qfull_t, Ufull_t, Tfull_t, ~, t] = solver_fluid_analysis_inner(qn, options);
end

Ufull0 = Ufull;
for i=1:M
    sd = find(Qfull(i,:)>0);
    Ufull(i,Qfull(i,:)==0)=0;
    switch qn.sched{i}
        case SchedStrategy.FCFS
            for k=sd
                % correct for the real rates, instead of the diffusion
                % approximation rates
                Ufull(i,k) = min([1,Qfull(i,k)/S(i),sum(Ufull0(i,sd)) * (Tfull(i,k)./rates0(i,k))/sum(Tfull(i,sd)./rates0(i,sd))]);
            end
    end
end
Ufull(isnan(Ufull))=0;

for i=1:M
    sd = find(Qfull(i,:)>0);
    Rfull(i,Qfull(i,:)==0)=0;
    for k=sd
        switch qn.sched{i}
            case SchedStrategy.FCFS
                Rfull(i,k) = Qfull(i,k) / Tfull(i,k);
        end
    end
end
Rfull(isnan(Rfull))=0;

for k=1:K
    if qn.refstat(k)>0 % ignore artificial classes
        Xfull(k) = Tfull(qn.refstat(k),k);
        Cfull(k) = qn.njobs(k) ./ Xfull(k);
    end
end

lastSolution.odeStateVec = ymean{end};
lastSolution.qn = qn;
%if options.verbose
%    fprintf(1,'Fluid analysis completed in %0.6f sec [%d iterations]\n',outer_runtime,outer_iters);
%end
end
