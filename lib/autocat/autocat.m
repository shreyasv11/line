function [x, pi, Q, stats, xls, xus] = autocat(R, AP, SOLVER, RELAXATION, POLICY,verbose, BORDER)
% PURPOSE:
% search for a RCAT product-form by relaxation-linearization + cuts
%---------------------------------------------------
% USAGE: [x, pi, Q, stats] = autocat(R, AP, SOLVER, POLICY)
% where:
%---------------------------------------------------
% RETURNS a vector of output arguments composed of:
% --------------------------------------------------
% REFERENCES:
% --------------------------------------------------
% VERSIONING:
%
% 0.0.7 - 31/Oct/2010 - added approximations
% 0.0.6 - 29/Oct/2010 - added zero potential relaxation
% 0.0.5 - 24/Oct/2010 - added soft constraints, policies, minresidual
% 0.0.4 - 20/Oct/2010 - added tlpr and decomposed into multiple functions
% 0.0.3 - 15/Oct/2010 - various fixes and new two-way synchs format
% 0.0.2 - 26/Sep/2010 - now only bound update iterations
% 0.0.1 - 14/Sep/2010 - basic RCAT implementation
%---------------------------------------------------
% EXAMPLE:
% Date: 14-Sep-2010 18:40:25

%% initialization
%warning off;
%c = onCleanup(@() save('autocat_lastenv.mat'));

% decide policy
if nargin < 3
    %SOLVER = 'fmincon';
    % SOLVER = 'cplex';
    SOLVER = 'linprog';
    % SOLVER = 'cplex';
    % SOLVER = 'sedumi';
    % SOLVER = 'glpk';
    %[''|sdpt3|sedumi|sdpa|pensdp|penbmi|csdp|dsdp|maxdet|lmilab|cdd|cplex|xpress|mosek|nag|quadprog|linprog|bnb|bmibnb|kypd|mpt|none ('')]
end


if nargin < 4
    RELAXATION = 'auto';
end

% decide policy
if nargin < 5
    policyfun = @() policy_vol();
    POLICY = 'vol';
else
    switch POLICY
        case {'lu'}
            policyfun = @() policy_lu();
        case {'l'}
            policyfun = @() policy_l();
        case {'u'}
            policyfun = @() policy_u();
        case {'vol'}
            policyfun = @() policy_vol();
        case {'volu'}
            policyfun = @() policy_volu();
    end
end

if nargin < 6
    verboselvl = 0;
    fout = 1;
else
    switch verbose
        case {'default'}
            verboselvl = 0;
            fout = 1;
        case {'silent'}
            verboselvl = 0;
            fout = 1;%fopen('null.tmp');
        case {'verbose'}
            verboselvl = 1;
            fout = 1;
        case {'log'}
            verboselvl = 1;
            fout = fopen(sprintf('log_autocat_%d.txt',randi(1000,1,1)));
            c = onCleanup(@() fclose(fout));
        otherwise
            verboselvl = 0;
            fout = 1;
    end
end

switch RELAXATION
    case {'ens','qcp'}
        if strcmpi(SOLVER,'fmincon')~=0
            fprintf(1,'solver solver option ignored for ens and qcp\n')
        end
        SOLVER = 'fmincon';
        verboselvl = 2;
end

    function options = get_solver_options()
        switch SOLVER
            case {'cplex'}
                options = sdpsettings('verbose',verboselvl,'solver',SOLVER,'usex0',0,'cachesolvers',0,'dimacs',0,'shift',1);
            otherwise
                options = sdpsettings('verbose',verboselvl,'solver',SOLVER,'usex0',0,'cachesolvers',0,'dimacs',0,'shift',0);
        end
    end

options = get_solver_options;

%% define model and scale rates
A=size(AP,1);
ACT=AP(:,1);
PSV=AP(:,2);
M=max(AP(:));

Aa={R{1:end-1,1}};
Pb={R{1:end-1,2}};
L={R{end,1:end}};
N = zeros(1,M); 
for i=1:M 
    N(i) = length(L{i}); 
end

if nargin < 7
    for i=1:M
        BORDER{i} =  [];
    end
end

gap = Inf;
g = {};
% scale rates in [0,0.9990]
scale = 1.0;
switch RELAXATION
    case {'tzpr1inf','tzpr0inf','tlpr1inf','tlpr0inf','apx_tma1inf'}
        for a=1:A
            for i=1:M
                scale=max([scale,max(sum(abs(R{end,i}),2)),max(sum(abs(R{a,1}),2))]);
            end
        end
        scale = 1.1*scale;
    otherwise
        scale = 1.0;
end
for a=1:A, Aa{a} = Aa{a}/scale; end
for i=1:M, L{i} = L{i}/scale; end

%% define constants
active = 1;
passive = 2;
switch RELAXATION
    case {'qcp'}
        MAXITER = 1000;
    otherwise
        MAXITER = 4*2*A;
end
PFTOL = 1e-4; % tolerance to declare that a product-form has been found
GAPTOL = 0.002; % gap tolerance to declare that a product-form has been found
%RETRIALS = 2*A;
% statistical variables
stats = struct('action_seq',[],'bound_seq',[],'rc1',[],'rc2',[],'rc3',[],'iter',0,'tot_time',0,'xs',[]);

%% define optimization variables
Q = cell(M,1);
x = sdpvar(A,1,'full'); % rates of passive actions
% initialize p vectors
pi = cell(M,1);

% initialize z vectors
z = cell(A,2);
for a=1:A
    z{a,1} = sdpvar(1,N(ACT(a)),'full'); % x(c)*pi{k}, k active in c - required for C3
    z{a,2} = sdpvar(1,N(PSV(a)),'full'); % x(c)*pi{k}, k passive in c  - required for pi*Q=0
end

% initialize x bounds
xL = zeros(A,1);
xU = zeros(A,1);
for a = 1:A
    xU(a) = max(Aa{a}*e(N(ACT(a))));
    xL(a) = max([PFTOL, min(Aa{a}*e(N(ACT(a))))]);
end

% initialize p bounds
piU = cell(M,1);
piL = cell(M,1);
for i=1:M
    % equilibrium state probabilities of process k
    piU{i} = ones(1,N(i));
    piL{i} = zeros(1,N(i));
end
bestc3=Inf;
xls = {xL};
xus = {xU};

%% main loop
    function header
        fprintf(fout,'\n _   _|_ _  _ _ _|_   \n');
        fprintf(fout,'(_||_|| (_)(_(_| |                                                      (c) Imperial College London, 2010\n');
        fprintf(fout,'=========================================================================================================\n');
        fprintf(fout,'autocat - version 0.0.7 - Oct/2010');
        fprintf(fout,'\nAuthors: Giuliano Casale and Peter G. Harrison');
        fprintf(fout,'\nAESOP group, Dept. of Computing, Imperial College London');
        fprintf(fout,'\nTool maintainer: Giuliano Casale (g.casale@imperial.ac.uk)');
        fprintf(fout,'\n=========================================================================================================');
        fprintf(fout,'\ninit:\t M = %d processes',M);
        fprintf(fout,'\ninit:\t A = %d actions',A);
        fprintf(fout,'\ninit:\t largest process has %d states',max(N));
        fprintf(fout,'\ninit:\t solver is %s',options.solver);
        fprintf(fout,'\ninit:\t policy is %s',POLICY);
        fprintf(fout,'\ninit:\t relaxation is %s',RELAXATION);
        fprintf(fout,'\ninit:\t product-form numerical tolerance = %d',PFTOL);
        fprintf(fout,'\ninit:\t scale factor = %0.6f',scale);
        fprintf(fout,'\ninit:\t max iter = %d',MAXITER);
        fprintf(fout,'\n\n');
    end
if verboselvl >0
    header;
end
fprintf(fout,'lps  rate  bnd   value       delta         gap       maxgap     c1 c2   c3     time   scv   rlx')
fprintf(fout,'\n---------------------------------------------------------------------------------------------------------\n')


while 1
    stats.iter = stats.iter + 1;
    
    %% execute policy
    if stats.iter <= A
        policyfun();
        if strcmpi(RELAXATION,'auto')
            lpRelaxation = 'lpr';
        else
            lpRelaxation = RELAXATION;
        end
    elseif stats.iter <= 2*A
        policyfun();
        if strcmpi(RELAXATION,'auto')
            lpRelaxation = 'lpr';
        end
    elseif stats.iter <= 3*A
        policyfun();
        if strcmpi(RELAXATION,'auto')
            lpRelaxation = 'tlpr1inf';
        end
    else
        policyfun();
        maxU = 2;
        U = min([maxU,floor(stats.iter/A)]);
        if strcmpi(RELAXATION,'auto')
            lpRelaxation = 'tlprUinf';
        end
    end
    
    %% generate lp relaxation
    nVar=-1; nCon=-1;
    switch lpRelaxation
        case {'ens'}
            [x, pi, CON, MCC, funmsg] = ens(x, pi);
        case {'qcp'}
            [x, pi, sp, sm, CON, MCC, funmsg] = qcp(x, pi);
        case {'lpr'}
            [x,pi,z,CON, MCC, funmsg] = lpr(x, pi, z);
        case {'zpr'}
            if stats.iter == 1
                x0 = {}; pi0 = {}; Q0 = {};
                R0 = 1;
                for r=1:R0
                    x0{r} = xU.*rand(A,1);
                    [pi0r,Q0r] = compute_equilibrium(x0{r});
                    for k=1:M
                        pi0{r,k} = pi0r{k};
                        Q0{r,k} = Q0r{k};
                    end
                end
            end
            [x,pi,z,LPR,MCC] = lpr(x, pi, z);
            [x,pi,z,g,CON,funmsg] = zpr(LPR, x, pi, z, x0, pi0, Q0);
        case {'tlpr0inf'}
            [x,pi,z,LPR,MCC] = lpr(x, pi, z);
            [x,pi,z,CON,funmsg] = tlprUinf(LPR, x, pi, z, 0);
        case {'tlpr1inf'}
            [x,pi,z,LPR,MCC] = lpr(x, pi, z);
            [x,pi,z,CON,funmsg] = tlprUinf(LPR, x, pi, z, 1);
        case {'tlprUinf'}
            [x,pi,z,LPR,MCC] = lpr(x, pi, z);
            [x,pi,z,CON,funmsg] = tlprUinf(LPR, x, pi, z, U);
        case {'tzpr1inf'}
            if stats.iter == 1
                x0 = {}; pi0 = {}; Q0 = {};
                R0 = 1;
                for r=1:R0
                    x0{r} = xU.*rand(A,1);
                    [pi0r,Q0r] = compute_equilibrium(x0{r});
                    for k=1:M
                        pi0{r,k} = pi0r{k};
                        Q0{r,k} = Q0r{k};
                    end
                end
            end
            [x,pi,z,LPR,MCC] = lpr(x, pi, z);
            [x,pi,z,g,CON,funmsg] = tzprUinf(LPR, x, pi, z, x0, pi0, Q0,1);
        case {'apx_ma'}
            [x,pi,z,CON,MCC,funmsg] = apx_ma(x, pi, z);
        case {'apx_tma1inf'}
            [x,pi,z,APX,MCC,funmsg] = apx_ma(x, pi, z);
            [x,pi,z,CON,funmsg] = tlprUinf(APX, x, pi, z, 1);
            funmsg = 'tma1inf';
            
        otherwise
            error(sprintf('solver %s is an unsupported relaxation.\n',lpRelaxation))
    end
    
    switch lpRelaxation
        case {'qcp'}
            OBJ = sum(sp{1}) + sum(sm{1});
            for i=2:M
                OBJ = OBJ + sum(sp{i}) + sum(sm{i});
            end
        otherwise
            if stats.bound_seq(end) == 0 % lb
                OBJ = x(stats.action_seq(end));
                bndType = 'L';
            elseif stats.bound_seq(end) == 1 % ub
                OBJ = -x(stats.action_seq(end));
                bndType = 'U';
            end
    end
    
    TRUNC = [];
    for i=1:M
        
        for s = BORDER{i}
            TRUNC = [ TRUNnchains; pi{i}(s) <= PFTOL ];
        end
    end
    
    %% run solver
    diagnostics = solvesdp([CON,MCC,TRUNC], OBJ, options);
    stats.tot_time = stats.tot_time + diagnostics.solvertime;
    stats.xs(end+1,1:A) = scale * double(x);
    xls{stats.iter} = xL;
    xus{stats.iter} = xU;
    %stats.xs(end,:)
    conditonInfeas = diagnostics.problem == 1 ... % yalmip detected infasibility
        || (strcmpi(SOLVER,'fmincon') && diagnostics.problem == 5) ... % lack of progress
        || (strcmpi(SOLVER,'cplex') && diagnostics.problem == 4) ... % numerical problems
        || (strcmpi(SOLVER,'cplex') && diagnostics.problem == 9); % basis singular
    if diagnostics.problem ~= 0 || conditonInfeas
        %        fprintf(fout,'\nsolver %s',diagnostics.info)
        %        fprintf(fout,'\nsolver failed to solve problem with %d variables and %d constraints/bounds',nVar,nCon)
        %% infeasible problem
        % suspected no product-form
        %{
        if RETRIALS > 0
            switch lpRelaxation
                case {'lpr'}
                    RELAXATION = 'lpr';
                    RETRIALS = RETRIALS - 1;
                    if RETRIALS <= A
                        options = sdpsettings('verbose',0,'solver','sedumi','usex0',1,'cachesolvers',1);
                        fprintf(fout,'\nsolver switching to sedumi')
                    else
                        options = sdpsettings('verbose',0,'solver',SOLVER,'usex0',1,'cachesolvers',1); % turn on verbose
                    end
                    fprintf(fout,'\nsolver trying with the most stable lp relaxation (lpr)')
                    continue
                case {'tlpr1inf','tlprUinf'}
                    % there may be numerical problems, retry with lpr
                    RELAXATION = 'lpr';
                    RETRIALS = RETRIALS - 1;
                    if RETRIALS <= A
                        stats.action_seq(end) = [];
                        stats.bound_seq(end) = [];
                        options = sdpsettings('verbose',0,'solver','sedumi','usex0',1,'cachesolvers',1);
                        fprintf(fout,'\nsolver switching to sedumi')
                    else
                        options = sdpsettings('verbose',0,'solver',SOLVER,'usex0',1,'cachesolvers',1); % turn on verbose
                    end
                    fprintf(fout,'\nsolver trying with the most stable lp relaxation (lpr)')
                    continue
            end
        end
        %}
        
        fprintf(fout,'solver infeasibility or no exact product-form exists, stepping into approximation mode')
        if verboselvl > 0
            fprintf(fout,'\nsolver Current reversed rate bounds')
            for a = 1:A
                fprintf(fout,'\n\t x(%d) in [%0.16f,%0.16f]',a,double(xL(a))*scale,double(xU(a))*scale);
            end
        end
        fprintf(fout,'\n')
        %methodApprox = 'apx_minres';
        methodApprox = 'apx_ma';
        %methodApprox = 'apx_tma1inf';
        switch methodApprox
            case {'apx_tma1inf'}
                %                fprintf(fout,'\nminres: running mean approximation\n')
                lpRelaxation = 'apx_tma1inf';
                continue
            case {'apx_ma'}
                %                fprintf(fout,'\nminres: running mean approximation\n')
                lpRelaxation = 'apx_ma';
                continue
            case {'apx_minres'}
                fprintf(fout,'\nminres: running mininum residual approximation')
                apx_x = sdpvar(A,1,'full'); % rates of passive actions
                [apx_x, nope, nope, nope, APX_CON, APX_MCC, APP_OBJ, funmsgs] = apx_minres1(apx_x, pi, z);
                apx_options = sdpsettings('verbose',0,'solver','cplex','usex0',1,'cachesolvers',1);
                apx_diagnostics = solvesdp([APX_CON,APX_MCC], sum(APP_OBJ), apx_options);
                stats.tot_time = stats.tot_time + apx_diagnostics.solvertime;
            otherwise
                error('you cannot be here');
        end
        fprintf(fout,'\nsolver approximation completed in %3.3f seconds', apx_diagnostics.solvertime)
        [pi,Q] = compute_equilibrium(apx_x);
        stats.rc1(stats.iter) = decide_rc1();
        stats.rc2(stats.iter) = decide_rc2();
        stats.rc3(stats.iter) = decide_rc3(pi);
        fprintf(fout,'\nsolver approximation results\n')
        for a = 1:A
            fprintf(fout,'\t x(%d) = %0.16f ',a,double(scale*x(a)));
            MAP = normalize({Q{ACT(a)}-Aa{a},Aa{a}});
            %fprintf(fout,'\t scv(%d) = %0.6f\n', a, map_scv(MAP));
            fprintf(fout,'\t scv(%d) = %0.6f\n', a, NaN);
        end
        x = double(scale*apx_x);
        for i=1:M
            Q{i} = makeinfgen(scale*Q{i});
        end
        %continue
        return
    elseif diagnostics.problem ~= 0
        %% other problems
        diagnostics
        fprintf(fout,'\n\nsolver %s\n',diagnostics.info)
        x = double(x*scale);
        [pi,Q] = compute_equilibrium(x);
        for i=1:M
            Q{i} = makeinfgen(scale*Q{i});
        end
        return
    end
    
    %% evaluate feasible solution
    
    switch lpRelaxation
        case {'qcp'}
            fprintf(fout,'%3d ', stats.iter);
            fprintf(fout,' -----  S  ');
            fprintf(fout,'-----------------------------------------------');
        otherwise
            % update data
            newxBnd = abs(double(OBJ));
            
            fprintf(fout,'%3d ', stats.iter);
            fprintf(fout,' x(%2d)  %c  ',stats.action_seq(end), bndType);
            %RETRIALS = 2*A; % earn back all retrials if got a feasible sol
            options = get_solver_options;
            if stats.bound_seq(end)==0
                oldxBnd = xL(stats.action_seq(end)); xL(stats.action_seq(end)) = min([max([newxBnd,xL(stats.action_seq(end))]),xU(stats.action_seq(end))]);
            elseif stats.bound_seq(end)==1
                oldxBnd = xU(stats.action_seq(end)); xU(stats.action_seq(end)) = max([min([newxBnd,xU(stats.action_seq(end))]),xL(stats.action_seq(end))]);
            end
            
            gap(stats.action_seq(end)) =  abs(1-xU(stats.action_seq(end))/xL(stats.action_seq(end)));
            fprintf(fout,'%0.6f %12f %11f %12f', newxBnd*scale, newxBnd/oldxBnd-1,gap(stats.action_seq(end)),max(gap));
    end
    
    [pi,Q] = compute_equilibrium(x);
    stats.rc1(stats.iter) = decide_rc1();
    stats.rc2(stats.iter) = decide_rc2();
    stats.rc3(stats.iter) = decide_rc3(pi);
    
    %    if gap best C3 seen so far
    %     if bestc3 > C3(end)
    %         bestc3 = C3(end);
    %         xbestc3 = double(x);
    %         [pic3,Qc3] = compute_equilibrium(xbestc3);
    %     end
    
    fprintf(fout,'   %1d  %1d %0.5f  %05.2fs', stats.rc1(stats.iter), stats.rc2(stats.iter), stats.rc3(stats.iter), stats.tot_time);
    for a = 1:A
        MAP = normalize({Q{ACT(a)}-Aa{a},Aa{a}});
        scvmap(a)=NaN;%map_scv(MAP);
    end
    maxscvgap = max(abs(1-scvmap));
    fprintf(fout,' %.3f', maxscvgap);
    fprintf(fout,' %s\n', funmsg);
    
    %if stats.iter >= MAXITER || stats.tot_time > 3600 || (stats.rc1(stats.iter) == 1 && stats.rc2(stats.iter) == 1 && stats.rc3(stats.iter) <= PFTOL) || max(gap) < GAPTOL
    if stats.iter >= MAXITER || stats.tot_time > 3*3600 || (stats.rc1(stats.iter) == 1 && stats.rc2(stats.iter) == 1 && stats.rc3(stats.iter) <= PFTOL)
        %% exit autocat
        fprintf(fout,'\nsolver analyzed a problem with %d variables and %d constraints/bounds \n',nVar,nCon)
        if (stats.rc1(stats.iter) == 1 && stats.rc2(stats.iter) == 1 && stats.rc3(stats.iter) <= PFTOL)
            fprintf(fout,'solver successfully found a product form solution in %3.3f sec\n',stats.tot_time(end))
        else
            fprintf(fout,'solver interrupted execution after %3.3f sec\n',stats.tot_time(end))
        end
        for a=1:A
            fprintf(fout,'\t x(%d) = %0.16f ',a,double(x(a))*scale);
            MAP = normalize({Q{ACT(a)}-Aa{a},Aa{a}});
            %fprintf(fout,'\t scv(%d) = %0.6f\n', a, map_scv(MAP));
            fprintf(fout,'\t scv(%d) = %0.6f\n', a, NaN);
        end
        [pi,Q] = compute_equilibrium(x);
        x=double(x*scale);
        for i=1:M
            Q{i} = makeinfgen(scale*Q{i});
        end
        return
    end
end

%% utility
    function [pi,Q] = compute_equilibrium(xsol)
        Q = cell(1,M);
        pi = cell(1,M);
        for myk=1:M
            Q{myk} = L{myk} - diag(L{myk}*e(N(myk))); %eps action
            for myc = 1:A
                if PSV(myc) == myk
                    Q{myk} = Q{myk}  + double(xsol(myc))*Pb{myc} - diag(Pb{myc}*e(N(myk)));
                elseif ACT(myc) == myk
                    Q{myk} = Q{myk}  + Aa{myc} - diag(Aa{myc}*e(N(myk)));
                end
            end
            Q{myk} = makeinfgen(Q{myk});
            pi{myk} = ctmc_solve(Q{myk});
        end
    end

%% product-form criteria
    function RC1 = decide_rc1()
        RC1 = 1; % passive always enabled
        
        for myj = 1:M
            for myAction = 1:A
                if PSV(myAction) == myj % if j is a passive process for action a
                    if any(find(Pb{myAction}*e(N(myj)) == 0))
                        RC1 = 0;
                        return
                    end
                end
            end
        end
    end

    function RC2 = decide_rc2()
        RC2 = 1; % active always enabled
        
        for myj = 1:M
            for myAction = 1:A
                if ACT(myAction) == myj % if j is the active process for action a
                    if any(find(Aa{myAction}'*e(N(myj)) == 0))
                        RC2 = 0;
                        return
                    end
                end
            end
        end
    end

    function RC3 = decide_rc3(pi)
        % evaluate C3
        RC3 = [];
        for myj=1:M
            for myAction = 1:A
                if ACT(myAction) == myj
                    RC3(end+1) = norm(pi{myj}*Aa{myAction}-double(x(myAction))*pi{myj});
                end
            end
        end
        RC3 = mean(RC3)*scale;
    end

%% policies

    function policy_lu()
        if isempty(stats.action_seq)
            stats.action_seq(end+1) = 1;
            stats.bound_seq(end+1) = 0;
            return
        else
            if stats.bound_seq(end) == 0
                stats.action_seq(end+1) = stats.action_seq(end);
                stats.bound_seq(end+1) = 1;
                return
            end
            for myAction=[stats.action_seq(end)+1:A,1:stats.action_seq(end)]
                stats.action_seq(end+1) = myAction;
                stats.bound_seq(end+1) = 0;
                return
            end
        end
    end

    function policy_l()
        if isempty(stats.action_seq)
            stats.action_seq(end+1) = 1;
            stats.bound_seq(end+1) = 0;
            return
        else
            for myAction=[stats.action_seq(end)+1:A,1:stats.action_seq(end)]
                stats.action_seq(end+1) = myAction;
                stats.bound_seq(end+1) = 0;
                return
            end
        end
    end

    function policy_u()
        if isempty(stats.action_seq)
            stats.action_seq(end+1) = 1;
            stats.bound_seq(end+1) = 1;
            return
        else
            for myAction=[stats.action_seq(end)+1:A,1:stats.action_seq(end)]
                stats.action_seq(end+1) = myAction;
                stats.bound_seq(end+1) = 1;
                return
            end
        end
    end

    function policy_vol()
        if isempty(stats.action_seq)
            stats.action_seq(end+1) = 1;
            stats.bound_seq(end+1) = 0;
            return
        else
            if stats.bound_seq(end) == 0
                stats.action_seq(end+1) = stats.action_seq(end);
                stats.bound_seq(end+1) = 1;
                return
            end
            [nope,pos] = sort(xU-xL,'descend');
            for myAction=pos(:)'
                if isempty(find(myAction == stats.action_seq(max([1,end-2*(A-1)+1]):end), 1))
                    stats.action_seq(end+1) = myAction;
                    stats.bound_seq(end+1) = 0;
                    return
                end
            end
        end
        return
    end

    function policy_volu()
        if isempty(stats.action_seq)
            stats.action_seq(end+1) = 1;
            stats.bound_seq(end+1) = 1;
            return
        else
            [nope,pos] = sort(xU-xL,'descend');
            for myAction=pos(:)'
                if isempty(find(myAction == stats.action_seq(max([1,end-2*(A-1)+1]):end), 1))
                    stats.action_seq(end+1) = myAction;
                    stats.bound_seq(end+1) = 0;
                    return
                end
            end
        end
        return
    end

%% relaxation programs

    function MCC = mcc(x,pi,z)
        MCC = [x >= xL, x <= xU];
        for myk=1:M
            % McCormick
            for myc = 1:A
                if PSV(myc) == myk
                    MCC = [MCC, z{myc,passive} >= piL{myk}*x(myc) + pi{myk}*xL(myc) - piL{myk}*xL(myc)];
                    MCC = [MCC, z{myc,passive} <= piL{myk}*x(myc) + pi{myk}*xU(myc) - piL{myk}*xU(myc)];
                    MCC = [MCC, z{myc,passive} <= piU{myk}*x(myc) + pi{myk}*xL(myc) - piU{myk}*xL(myc)];
                    MCC = [MCC, z{myc,passive} >= piU{myk}*x(myc) + pi{myk}*xU(myc) - piU{myk}*xU(myc)];
                elseif ACT(myc) == myk
                    MCC = [MCC, z{myc,active} >= piL{myk}*x(myc) + pi{myk}*xL(myc) - piL{myk}*xL(myc)];
                    MCC = [MCC, z{myc,active} <= piL{myk}*x(myc) + pi{myk}*xU(myc) - piL{myk}*xU(myc)];
                    MCC = [MCC, z{myc,active} <= piU{myk}*x(myc) + pi{myk}*xL(myc) - piU{myk}*xL(myc)];
                    MCC = [MCC, z{myc,active} >= piU{myk}*x(myc) + pi{myk}*xU(myc) - piU{myk}*xU(myc)];
                end
            end
        end
    end

    function [x,pi,CON,MCC,funmsg] = ens(x, pi)
        funmsg = 'ens';
        CON =[];
        nVar = length(x);
        nCon = 0;
        for k=1:M
            nVar = nVar + length(pi{k});
            nCon = nCon + 1 ;
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, pi{k}*e(N(k)) == 1];
            
            % constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + x(c)*pi{k}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            nCon = nCon + N(k);
            CON = [CON, piQ{k} == 0];
            
            % constraint C3
            for c = 1:A
                if ACT(c) == k
                    nCon = nCon + N(k);
                    CON = [CON,reshape((x(c)*pi{k}*eye(N(k))-pi{k}*Aa{c}),1,N(k)) == 0];
                end
            end
            
        end
        MCC = [];
    end

    function [x,pi,sp,sm,CON,MCC,funmsg] = qcp(x, pi)
        funmsg = 'ens';
        CON =[];
        nVar = length(x);
        nCon = 0;
        for k=1:M
            nVar = nVar + length(pi{k});
            nCon = nCon + 1 ;
            pi{k} = sdpvar(1,N(k),'full');
            sp{k} = sdpvar(1,N(k),'full');
            sm{k} = sdpvar(1,N(k),'full');
            CON = [CON, pi{k}*e(N(k)) == 1, sp{k} >=0, sm{k} >=0];
            
            % constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + x(c)*pi{k}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            nCon = nCon + N(k);
            CON = [CON, piQ{k} == 0];
            
            % constraint C3
            for c = 1:A
                if ACT(c) == k
                    nCon = nCon + N(k);
                    CON = [CON,reshape((x(c)*pi{k}*eye(N(k))-pi{k}*Aa{c}),1,N(k)) == sp{k} + sm{k}];
                end
            end
            
        end
        MCC = [];
    end

    function [x,pi,z,CON,MCC,funmsg] = lpr(x, pi, z)
        funmsg = 'lpr';
        CON =[];
        for k=1:M
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, 1-PFTOL <= pi{k}*e(N(k)) <= 1+PFTOL];
            CON = [CON, pi{k} >= piL{k}-PFTOL, pi{k} <= piU{k}+PFTOL];
            
            %% constraint pi_k * 1 == 1
            for c = 1:A
                if PSV(c) == k
                    CON = [CON, x(c) - PFTOL*pi{k} <= z{c,passive}*e(N(k)) <= x(c) + PFTOL*pi{k}];
                elseif ACT(c) == k
                    CON = [CON, x(c) - PFTOL*pi{k} <= z{c,active}*e(N(k)) <= x(c) + PFTOL*pi{k}];
                end
            end
            
            %% constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + z{c,passive}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            CON = [CON, -PFTOL <= piQ{k} <= PFTOL];
            
            %% constraint C3
            for c = 1:A
                if ACT(c) == k
                    CON = [CON, -PFTOL*pi{k} <= reshape((z{c,active}*eye(N(k))-pi{k}*Aa{c}),1,N(k)) <= PFTOL*pi{k}];
                    %CON = [CON, -PFTOL*pi{k} <= reshape((z{c,active}*eye(N(k))*e(N(k))-pi{k}*Aa{c}*e(N(k))),1,1) <= PFTOL*pi{k}];
                end
            end
            
        end
        MCC = mcc(x,pi,z);
    end

    function [x,pi,z,CON,funmsg] = tlprUinf(CON, x, pi, z, U)
        funmsg = sprintf('tlpr%dinf',U);
        for k=1:M
            
            % constraint pi*Q=0 - u
            piQU = {};
            for u = 1:U
                for b = 1:A
                    if ACT(b) == k
                        piQU{b,k,u} = z{b,active}*(Aa{b}^(u-1))*(L{k} - diag(L{k}*e(N(k)))); % eps action
                        for c = 1:A
                            if PSV(c) == k
                                piQU{b,k,u} = piQU{b,k,u}  + z{c,passive}*(Aa{b}^u)*(Pb{c} - diag(Pb{c}*e(N(k))));
                            elseif ACT(c) == k
                                piQU{b,k,u} = piQU{b,k,u}  + z{b,active}*(Aa{b}^(u-1))*(Aa{c} - diag(Aa{c}*e(N(k))));
                            end
                        end
                        CON = [CON, -PFTOL*pi{k} <= piQU{b,k,u} <= PFTOL*pi{k}];
                    end
                end
            end
            
            % constraint pi*Q=0 - inf
            piQinf = {};
            for b = 1:A
                if ACT(b) == k
                    piQinf{b,k} = z{b,active}*inv(eye(N(k))-Aa{b})*(L{k} - diag(L{k}*e(N(k)))); % eps action
                    for c = 1:A
                        if PSV(c) == k
                            piQinf{b,k} = piQinf{b,k}  + z{c,passive}*Aa{b}*inv(eye(N(k))-Aa{b})*(Pb{c} - diag(Pb{c}*e(N(k))));
                        elseif ACT(c) == k
                            piQinf{b,k} = piQinf{b,k}  + z{b,active}*inv(eye(N(k))-Aa{b})*(Aa{c} - diag(Aa{c}*e(N(k))));
                        end
                    end
                    CON = [CON, -PFTOL*pi{k} <= piQinf{b,k} <= PFTOL*pi{k}];
                end
            end
            
        end
        
    end

    function [x,pi,z,g,CON,funmsg] = zpr(CON, x, pi, z, x0, pi0, Q0)
        funmsg = 'zpr';
        for k=1:M
            
            % compute potential matrix
            for r=1:R0
                for n=1:N(k)
                    if stats.iter >= 1
                        f = zeros(N(k),1);
                        f(n) = 1;
                        g{r,k,n}  = potential_jacobi(Q0{r,k}, pi0{r,k}, f);
                    end
                end
            end
            
            % add potential constraints
            for r=1:R0
                delta{r,k} = pi0{r,k}-pi{k};
                for n=1:N(k)
                    for b=1:A
                        if PSV(b) == k
                            delta{r,k}(n) = delta{r,k}(n) + (z{b,passive}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                            delta{r,k}(n) = delta{r,k}(n) + (-x0{r}(b)*pi{k}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                        end
                    end
                end
                CON = [CON, -PFTOL <= delta{r,k} <= PFTOL];
            end
            
            for r=1:R0
                for c=1:A
                    if ACT(c) == k
                        delta{r,k} = x(c)*pi0{r,k}-z{c,active};
                        for n=1:N(k)
                            for b=1:A
                                if PSV(b) == k
                                    delta{r,k}(n) = delta{r,k}(n) + (z{b,passive}*Aa{c}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                                    delta{r,k}(n) = delta{r,k}(n) - (z{c,active}*x0{r}(b)*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                                end
                            end
                        end
                    end
                    CON = [CON, -PFTOL <= delta{r,k} <= PFTOL];
                end
            end
        end
    end

    function [x,pi,z,g,CON,funmsg] = tzprUinf(CON, x, pi, z, x0, pi0, Q0, U)
        funmsg = sprintf('tzpr%dinf',U);
        for k=1:M
            
            % compute potential matrix
            for r=1:R0
                for n=1:N(k)
                    if stats.iter >= 1
                        f = zeros(N(k),1);
                        f(n) = 1;
                        g{r,k,n}  = potential_jacobi(Q0{r,k}, pi0{r,k}, f);
                    end
                end
            end
            
            % add potential constraints
            for r=1:R0
                delta{r,k} = pi0{r,k}-pi{k};
                for n=1:N(k)
                    for b=1:A
                        if PSV(b) == k
                            delta{r,k}(n) = delta{r,k}(n) + (z{b,passive}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                            delta{r,k}(n) = delta{r,k}(n) + (-x0{r}(b)*pi{k}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                        end
                    end
                end
                CON = [CON, -PFTOL <= delta{r,k} <= PFTOL];
            end
            
            for r=1:R0
                for c=1:A
                    if ACT(c) == k
                        delta{r,k} = x(c)*pi0{r,k}-z{c,active};
                        for n=1:N(k)
                            for b=1:A
                                if PSV(b) == k
                                    delta{r,k}(n) = delta{r,k}(n) + (z{b,passive}*Aa{c}*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                                    delta{r,k}(n) = delta{r,k}(n) - (z{c,active}*x0{r}(b)*(Pb{b}-diag(Pb{b}*e(N(k)))))*g{r,k,n};
                                end
                            end
                        end
                    end
                    CON = [CON, -PFTOL <= delta{r,k} <= PFTOL];
                end
            end
            
            % constraint pi*Q=0 - u
            piQU = {};
            for u = 1:U
                for b = 1:A
                    if ACT(b) == k
                        piQU{b,k,u} = z{b,active}*(Aa{b}^(u-1))*(L{k} - diag(L{k}*e(N(k)))); % eps action
                        for c = 1:A
                            if PSV(c) == k
                                piQU{b,k,u} = piQU{b,k,u}  + z{c,passive}*(Aa{b}^u)*(Pb{c} - diag(Pb{c}*e(N(k))));
                            elseif ACT(c) == k
                                piQU{b,k,u} = piQU{b,k,u}  + z{b,active}*(Aa{b}^(u-1))*(Aa{c} - diag(Aa{c}*e(N(k))));
                            end
                        end
                        CON = [CON, -PFTOL*pi{k} <= piQU{b,k,u} <= PFTOL*pi{k}];
                    end
                end
            end
            
            % constraint pi*Q=0 - inf
            piQinf = {};
            for b = 1:A
                if ACT(b) == k
                    piQinf{b,k} = z{b,active}*inv(eye(N(k))-Aa{b})*(L{k} - diag(L{k}*e(N(k)))); % eps action
                    for c = 1:A
                        if PSV(c) == k
                            piQinf{b,k} = piQinf{b,k}  + z{c,passive}*Aa{b}*inv(eye(N(k))-Aa{b})*(Pb{c} - diag(Pb{c}*e(N(k))));
                        elseif ACT(c) == k
                            piQinf{b,k} = piQinf{b,k}  + z{b,active}*inv(eye(N(k))-Aa{b})*(Aa{c} - diag(Aa{c}*e(N(k))));
                        end
                    end
                    CON = [CON, -PFTOL*pi{k} <= piQinf{b,k} <= PFTOL*pi{k}];
                end
            end
            
        end
        
    end

%% approximation programs

    function [x,pi,z,CON,MCC,funmsg] = apx_ma(x, pi, z)
        funmsg = 'ma';
        CON =[];
        for k=1:M
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, 1-PFTOL <= pi{k}*e(N(k)) <= 1+PFTOL];
            CON = [CON, pi{k} >= piL{k}-PFTOL, pi{k} <= piU{k}+PFTOL];
            
            %% constraint pi_k * 1 == 1
            for c = 1:A
                if PSV(c) == k
                    CON = [CON, x(c) - PFTOL*pi{k} <= z{c,passive}*e(N(k)) <= x(c) + PFTOL*pi{k}];
                elseif ACT(c) == k
                    CON = [CON, x(c) - PFTOL*pi{k} <= z{c,active}*e(N(k)) <= x(c) + PFTOL*pi{k}];
                end
            end
            
            %% constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + z{c,passive}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            CON = [CON, -PFTOL <= piQ{k} <= PFTOL];
            
            %% constraint C3
            for c = 1:A
                if ACT(c) == k
                    CON = [CON, -PFTOL*pi{k} <= reshape((z{c,active}*eye(N(k))*e(N(k))-pi{k}*Aa{c}*e(N(k))),1,1) <= PFTOL*pi{k}];
                end
            end
            
        end
        MCC = mcc(x,pi,z);
    end

    function [x,pi,sk,CON,OBJ,funmsg] = apx_va(x, pi)
        funmsg = 'va';
        sk = {};
        OBJ = [];
        CON = [];
        for k=1:M
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, pi{k}*e(N(k)) == 1];
            
            % constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + double(x(c))*pi{k}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            CON = [CON, piQ{k} == 0];
            
            % constraint C3
            for c = 1:A
                if ACT(c) == k
                    sk{end+1} = sdpvar(1,N(:),'full');
                    CON = [CON, reshape((double(x(c))*pi{k}*eye(N(k))-pi{k}*Aa{c}),1,N(k))*e(N(k))+sk{end}];
                    OBJ = [OBJ; norm(sk{end},1)];
                end
            end
        end
        OBJ = norm(OBJ);
    end

    function [x,pi,z,sk,CON,MCC,OBJ,funmsg] = apx_minres1(x, pi, z)
        funmsg = 'minres';
        active = 1;
        passive = 2;
        sk = {};
        OBJ = [];
        CON = [];
        for k=1:M
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, pi{k}*e(N(k)) == 1, pi{k} >= piL{k}, pi{k} <= piU{k}];
            
            % constraint pi_k * 1 == 1
            for c = 1:A
                if PSV(c) == k
                    CON = [CON, z{c,passive}*e(N(k)) == x(c)];
                elseif ACT(c) == k
                    CON = [CON, z{c,active}*e(N(k)) == x(c)];
                end
            end
            
            % constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + z{c,passive}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            
            CON = [CON, 0 <= piQ{k} <= 0];
        end
        
        
        % minresidual
        for k=1:M
            % constraint C3
            for c = 1:A
                if ACT(c) == k
                    sk{end+1} = sdpvar(1,N(:),'full');
                    CON = [CON, reshape((z{c,active}*eye(N(k))-pi{k}*Aa{c}),1,N(k))*e(N(k))+sk{end}];
                    OBJ = [OBJ; norm(sk{end},1)];
                end
            end
            
        end
        MCC = [x >= xL; x <= xU];
        for k=1:M
            % McCormick
            for c = 1:A
                if PSV(c) == k
                    MCC = [MCC, z{c,passive} >= piL{k}*x(c) + pi{k}*xL(c) - piL{k}*xL(c)];
                    MCC = [MCC, z{c,passive} <= piL{k}*x(c) + pi{k}*xU(c) - piL{k}*xU(c)];
                    MCC = [MCC, z{c,passive} <= piU{k}*x(c) + pi{k}*xL(c) - piU{k}*xL(c)];
                    MCC = [MCC, z{c,passive} >= piU{k}*x(c) + pi{k}*xU(c) - piU{k}*xU(c)];
                elseif ACT(c) == k
                    MCC = [MCC, z{c,active} >= piL{k}*x(c) + pi{k}*xL(c) - piL{k}*xL(c)];
                    MCC = [MCC, z{c,active} <= piL{k}*x(c) + pi{k}*xU(c) - piL{k}*xU(c)];
                    MCC = [MCC, z{c,active} <= piU{k}*x(c) + pi{k}*xL(c) - piU{k}*xL(c)];
                    MCC = [MCC, z{c,active} >= piU{k}*x(c) + pi{k}*xU(c) - piU{k}*xU(c)];
                end
            end
        end
        
    end

    function [x,pi,z,sk,CON,MCC,OBJ,funmsg] = apx_minres2(x, pi, z)
        funmsg = 'minres';
        active = 1;
        passive = 2;
        sk = {};
        OBJ = [];
        CON = [];
        for k=1:M
            pi{k} = sdpvar(1,N(k),'full');
            CON = [CON, pi{k}*e(N(k)) == 1, pi{k} >= piL{k}, pi{k} <= piU{k}];
            
            % constraint pi_k * 1 == 1
            for c = 1:A
                sk{k,c} = sdpvar(1,N(:),'full');
                if PSV(c) == k
                    CON = [CON, z{c,passive}*e(N(k)) == x(c)+sk{k,c}];
                elseif ACT(c) == k
                    CON = [CON, z{c,active}*e(N(k)) == x(c)+sk{k,c}];
                end
                OBJ = [OBJ; norm(sk{k,c},1)];
            end
            
            % constraint pi * Q = 0
            piQ{k} = pi{k}*(L{k} - diag(L{k}*e(N(k)))); % eps action
            for c = 1:A
                if PSV(c) == k
                    piQ{k} = piQ{k}  + z{c,passive}*(Pb{c} - diag(Pb{c}*e(N(k))));
                elseif ACT(c) == k
                    piQ{k} = piQ{k}  + pi{k}*(Aa{c} - diag(Aa{c}*e(N(k))));
                end
            end
            
            CON = [CON, 0 <= piQ{k} <= 0];
        end
        
        
        % minresidual
        for k=1:M
            % constraint C3
            for c = 1:A
                if ACT(c) == k
                    CON = [CON, reshape((z{c,active}*eye(N(k))-pi{k}*Aa{c}),1,N(k))*e(N(k))];
                    
                end
            end
            
        end
        MCC = [x >= xL; x <= xU];
        for k=1:M
            % McCormick
            for c = 1:A
                if PSV(c) == k
                    MCC = [MCC, z{c,passive} >= piL{k}*x(c) + pi{k}*xL(c) - piL{k}*xL(c)];
                    MCC = [MCC, z{c,passive} <= piL{k}*x(c) + pi{k}*xU(c) - piL{k}*xU(c)];
                    MCC = [MCC, z{c,passive} <= piU{k}*x(c) + pi{k}*xL(c) - piU{k}*xL(c)];
                    MCC = [MCC, z{c,passive} >= piU{k}*x(c) + pi{k}*xU(c) - piU{k}*xU(c)];
                elseif ACT(c) == k
                    MCC = [MCC, z{c,active} >= piL{k}*x(c) + pi{k}*xL(c) - piL{k}*xL(c)];
                    MCC = [MCC, z{c,active} <= piL{k}*x(c) + pi{k}*xU(c) - piL{k}*xU(c)];
                    MCC = [MCC, z{c,active} <= piU{k}*x(c) + pi{k}*xL(c) - piU{k}*xL(c)];
                    MCC = [MCC, z{c,active} >= piU{k}*x(c) + pi{k}*xU(c) - piU{k}*xU(c)];
                end
            end
        end
        
    end

    function [MAP]=normalize(MAP,TOL)
        if nargin==1
            TOL=eps;
        end
        nStates=size(MAP{1},1);
        nMAP=length(MAP);
        
        for n=1:nStates
            % recalculate the diagonal elements in D0 according to the other
            % elements in the same row
            MAP{1}(n,n)=0;
            for b=1:nMAP
                MAP{1}(n,n)=MAP{1}(n,n)-sum(MAP{b}(n,:));
            end
        end
        for i=1:nStates
            for j=1:nStates
                % if there is any complex element, replace them with their real
                % parts
                MAP{1}(i,j)=real(MAP{1}(i,j));
                MAP{2}(i,j)=real(MAP{2}(i,j));
            end
        end
    end
end

function g  = potential_jacobi(Q, pi, f)
TOL = 1e-10;
n = length(pi);
en = e(n);
M = diag(diag(-Q+en*pi));
N = diag(diag(-Q+en*pi)) + Q ;
g = ctmc_solve(Q)';
for iter = 1:10000
    g_1 = g;    
    h = pi*g;
    g   = M \ (N*g - en*h + f);
    if ( norm( g - g_1 ) / norm( g ) < TOL) break; end
end

end

function ldom = dominant(A)
    n = 10*length(A); % my choice, should be large
    ldom = trace((A^n)).^(1/n); % dominant eigenvalue of A
end