function [ymean, ymean_t, t, iter] = solver_fluid_iteration(qn, N, Lambda, Pi, P, S, ymean, ydefault, slowrate, Tstart, max_time, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

iter_max = options.iter_max;
verbose = options.verbose; 
tol = options.tol;
iter_tol = options.iter_tol;
stiff = options.stiff; 
timespan = options.timespan;

goon = true; % max stiff solver
iter = 0;
allt=[];
ally =[];
lastmsg = '';
t=[];
ymean_t=[];
% heuristic to select stiff or non-stiff ODE solver
nonZeroRates = slowrate(:);
nonZeroRates = nonZeroRates(nonZeroRates>0);
nonZeroRates = nonZeroRates(isfinite(nonZeroRates));
rategap = log10(max(nonZeroRates)/min(nonZeroRates)); % if the max rate is Distrib.InfRate and the min is 1, then rategap = 6

% init ode
[ode_h, ~] = solver_fluid_odes(N, Lambda, Pi, P, S, qn.sched, qn.schedparam);
T0 = timespan(1);
%opt = odeset();
%opt = odeset('AbsTol', min(10^(-rategap),1e-4), 'RelTol', 1e-3, 'NonNegative', 1:length(y0));
opt = odeset('AbsTol', tol, 'RelTol', tol, 'NonNegative', 1:length(ymean{1}));
T = 0;
while (isfinite(timespan(2)) && T < timespan(2)) || (goon && iter < iter_max)
    iter = iter + 1;
    if toc(Tstart) > max_time
        goon = false;
        break;
    end
    
    % determine entry state vector in e
    y0 = ymean{iter-1 +1};
    
    if iter == 1 % first iteration
        T = min(timespan(2),abs(10/min(nonZeroRates))); % solve ode until T = 1 event with slowest exit rate
    else
        T = min(timespan(2),abs(10*iter/min(nonZeroRates)));
    end
    
    try
        if stiff
            [t_iter, ymean_t_iter] = solveodestiff(y0);
        else
            [t_iter, ymean_t_iter] = solveode(y0);
        end
    catch me
%        switch me.identifier
%            case 'MATLAB:odearguments:SizeIC' % if the cached initial point fails
                fprintf(1,'Supplied initial point failed, Fluid solver switching to default initialization.\n');
                opt = odeset('AbsTol', tol, 'RelTol', tol, 'NonNegative', 1:length(ydefault));
                [t_iter, ymean_t_iter] = solveode(ydefault);
 %           otherwise
 %               me
 %               error('Unspecified ODE solver exception. Quitting.');
%        end
    end
    ymean_t(end+1:end+size(ymean_t_iter,1),:) = ymean_t_iter;
    t(end+1:end+size(t_iter,1),:) = t_iter;
    ymean{iter +1} = ymean_t(end,:);
    movedMassRatio = norm(ymean{iter +1} - ymean{iter-1 +1}, 1) / 2 / sum(ymean{iter-1 +1});
    T0  = T; % for next iteration
    
    if nargout>3
        if isempty(allt)
            allt = t;
        else
            allt = [allt; allt(end)+t];
        end
        ally = [ally; ymean_t];
    end
    
    % check termination condition
    
    if verbose > 0
        llmsg = length(lastmsg);
        if llmsg>0
            for ib=1:llmsg
                fprintf(1,'\b');
            end
        end
    end
    
    if movedMassRatio < iter_tol  % converged
        % stop only if this is not a transient analysis, in which case keep
        % going until the specified end time
    end
    
    if T >= timespan(2)
        goon = false;
    end
end

    function [t, yt_e] = solveode(y0)
        if tol <= 1e-3
            [t, yt_e] = feval(options.odesolvers.accurateOdeSolver, ode_h, [T0 T], y0, opt);
        else
            [t, yt_e] = feval(options.odesolvers.fastOdeSolver, ode_h, [T0 T], y0, opt);
        end
    end

    function [t, yt_e] = solveodestiff(y0)
        if tol <= 1e-3
            [t, yt_e] = feval(options.odesolvers.accurateStiffOdeSolver, ode_h, [T0 T], y0, opt);
        else
            opt.NonNegative = []; % not supported by ode23s
            [t, yt_e] = feval(options.odesolvers.fastStiffOdeSolver, ode_h, [T0 T], y0, opt);
        end
    end
end