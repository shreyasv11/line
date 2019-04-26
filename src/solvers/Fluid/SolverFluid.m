classdef SolverFluid < NetworkSolver
    % A solver based on fluid and mean-field approximation methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverFluid(model,varargin)
            % SELF = SOLVERFLUID(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function setOptions(self, options)
            % SETOPTIONS(OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        function RD = getTranCdfPassT(self, R)
            % RD = GETTRANCDFPASST(R)
            
            T0 = tic;
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles;
            end
            qn = self.getStruct;
            [s0, s0prior] = self.model.getState;
            for ind=1:qn.nnodes
                if qn.isstateful(ind)
                    isf = QN.nodeToStateful(ind);
                    if nnz(s0prior{isf})>1
                        error('getTranCdfPassT: multiple initial states have non-zero prior - unsupported.');
                    end
                    qn.state{isf} = s0{isf}(1,:); % assign initial state to network
                end
            end
            options = self.getOptions;
            [odeStateVec] = solver_fluid_initsol(qn, options);
            options.init_sol = odeStateVec;
            RD = solver_fluid_passage_time(qn, options);
            runtime = toc(T0);
            self.setDistribResults(RD, runtime);
        end
        
        function [Pnir,logPnir] = getProbStateAggr(self, ist)
            % [PNIR,LOGPNIR] = GETPROBSTATEAGGR(IST)
            
            if ~exist('ist','var')
                error('getProbStateAggr requires to pass a parameter the station of interest.');
            end
            if ist > self.model.getNumberOfStations
                error('Station number exceeds the number of stations in the model.');
            end
            if isempty(self.result)
                self.run;
            end
            Q = self.result.Avg.Q;
            qn = self.model.getStruct;
            N = qn.njobs;
            if all(isfinite(N))
                state = self.model.getState{qn.stationToStateful(ist)};
                [~, nir, ~, ~] = State.toMarginal(qn, ist, state, self.getOptions);
                % Binomial approximation with mean fitted to queue-lengths.
                % Rainer Schmidt, "An approximate MVA ...", PEVA 29:245-254, 1997.
                logPnir = 0;
                for r=1:size(nir,2)
                    logPnir = logPnir + nchoosekln(N(r),nir(r));
                    logPnir = logPnir + nir(r)*log(Q(ist,r)/N(r));
                    logPnir = logPnir + (N(r)-nir(r))*log(1-Q(ist,r)/N(r));
                end
                Pnir = real(exp(logPnir));
            else
                error('getProbStateAggr not yet implemented for models with open classes.');
            end
        end
        
        
        function RD = getCdfRespT(self, R)
            % RD = GETCDFRESPT(R)
            
            T0 = tic;
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles;
            end
            qn = self.getStruct;
            self.getAvg; % get steady-state solution
            options = self.getOptions;
            options.init_sol = self.result.solverSpecific.odeStateVec;
            RD = solver_fluid_passage_time(qn, options);
            runtime = toc(T0);
            self.setDistribResults(RD, runtime);
        end
        
        function supported = getSupported(self,supported)
            % SUPPORTED = GETSUPPORTED(SELF,SUPPORTED)
            
            if ~exist('supported','var')
                supported=struct();
            end
        end
        
        % solve method is supplied by Solver superclass
        function runtime = run(self)
            % RUNTIME = RUN()
            % Run the solver
            
            self.reset();
            T0=tic;
            options=self.options;
            
            if isinf(options.timespan(1))
                if options.verbose  == 2
                    warning('%s requires options.timespan(1) to be finite. Setting it to 0.',mfilename);
                end
                options.timespan(1) = 0;
            end
            
            if options.timespan(1) == options.timespan(2)
                warning('%s: timespan is a single point, unsupported. Setting options.timespace(1) to 0.\n',mfilename);
                options.timespan(1) = 0;
            end
            
            if ~self.supports(self.model)
                %                if options.verbose
                error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
                %                end
                %                runtime = toc(T0);
                %                return
            end
            
            qn = self.model.getStruct();
            
            M = self.model.getNumberOfStations;
            K = self.model.getNumberOfClasses;
            RT = 0;
            lastSol= [];
            Q = zeros(M,K); R = zeros(M,K); T = zeros(M,K);
            U = zeros(M,K); C = zeros(1,K); X = zeros(1,K);
            [s0, s0prior] = self.model.getState;
            s0_sz = cellfun(@(x) size(x,1), s0)';
            s0_id = pprod(s0_sz-1);
            while s0_id>=0 % for all possible initial states
                s0prior_val = 1;
                for ind=1:qn.nnodes
                    if qn.isstateful(ind)
                        isf = qn.nodeToStateful(ind);
                        s0prior_val = s0prior_val * s0prior{isf}(1+s0_id(isf)); % update prior
                        qn.state{isf} = s0{isf}(1+s0_id(isf),:); % assign initial state to network
                    end
                end
                if s0prior_val > 0
                    [Qfull, Ufull, Rfull, Tfull, Cfull, Xfull, t, Qfull_t, Ufull_t, Tfull_t, lastSol] = solver_fluid_analysis(qn, options);
                    [t,uniqueIdx] = unique(t);
                    if isempty(lastSol) % if solution fails
                        Q = NaN*ones(M,K); R = NaN*ones(M,K);
                        T = NaN*ones(M,K); U = NaN*ones(M,K);
                        C = NaN*ones(1,K); X = NaN*ones(1,K);
                        Qt = cell(M,K); Ut = cell(M,K); Tt = cell(M,K);
                        for ist=1:M
                            for r=1:K
                                Qt{ist,r} = [NaN,NaN];
                                Ut{ist,r} = [NaN,NaN];
                                Tt{ist,r} = [NaN,NaN];
                            end
                        end
                    else
                        if isempty(self.result) && ~exist('Qt','var')
                            Q = Qfull*s0prior_val;
                            R = Rfull*s0prior_val;
                            T = Tfull*s0prior_val;
                            U = Ufull*s0prior_val;
                            C = Cfull*s0prior_val;
                            X = Xfull*s0prior_val;
                            Qt = cell(M,K);
                            Ut = cell(M,K);
                            Tt = cell(M,K);
                            for ist=1:M
                                for r=1:K
                                    Qfull_t{ist,r} = Qfull_t{ist,r}(uniqueIdx);
                                    Ufull_t{ist,r} = Ufull_t{ist,r}(uniqueIdx);
                                    Tfull_t{ist,r} = Tfull_t{ist,r}(uniqueIdx);
                                    Qt{ist,r} = [Qfull_t{ist,r} * s0prior_val,t];
                                    Ut{ist,r} = [Ufull_t{ist,r} * s0prior_val,t];
                                    Tt{ist,r} = [Tfull_t{ist,r} * s0prior_val,t];
                                end
                            end
                        else
                            Q = Q + Qfull*s0prior_val;
                            R = R + Rfull*s0prior_val;
                            T = T + Tfull*s0prior_val;
                            U = U + Ufull*s0prior_val;
                            C = C + Cfull*s0prior_val;
                            X = X + Xfull*s0prior_val;
                            for ist=1:M
                                for r=1:K
                                    [t,uniqueIdx] = unique(t);
                                    Qfull_t{ist,r} = Qfull_t{ist,r}(uniqueIdx);
                                    Ufull_t{ist,r} = Ufull_t{ist,r}(uniqueIdx);
                                    %                                  Tfull_t{i,r} = Tfull_t{i,r}(uniqueIdx);
                                    
                                    tunion = union(Qt{ist,r}(:,2), t);
                                    dataOld = interp1(Qt{ist,r}(:,2),Qt{ist,r}(:,1),tunion);
                                    dataNew = interp1(t,Qfull_t{ist,r},tunion);
                                    Qt{ist,r} = [dataOld + s0prior_val * dataNew, tunion];
                                    
                                    dataOld = interp1(Ut{ist,r}(:,2),Ut{ist,r}(:,1),tunion);
                                    dataNew = interp1(t,Ufull_t{ist,r},tunion);
                                    Ut{ist,r} = [dataOld + s0prior_val * dataNew, tunion];
                                    
                                    %                                 dataOld = interp1(Tt{i,r}(:,2),Tt{i,r}(:,1),tunion);
                                    %                                 dataNew = interp1(t,Tfull_t{i,r},tunion);
                                    %                                 Tt{i,r} = [dataOld + s0prior_val * dataNew, tunion];
                                end
                            end
                        end
                    end
                end
                s0_id=pprod(s0_id,s0_sz-1); % update initial state
            end
            runtime = toc(T0);
            self.result.solverSpecific = lastSol;
            self.setAvgResults(Q,U,R,T,C,X,runtime);
            Rt={}; Xt={}; Ct={};
            self.setTranAvgResults(Qt,Ut,Rt,Tt,Ct,Xt,runtime);
        end
    end
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({
                'ClassSwitch','DelayStation','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'ClosedClass','Replayer'});  %,'Sink','Source','OpenClass','JobSink'
            %SolverFluid has very weak performance on open models
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverFluid.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)
            
            % do nothing
        end
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            
            options = Solver.defaultOptions();
            options.iter_max = 50;
            options.stiff = true;
            options.timespan = [0,Inf];
        end
    end
end
