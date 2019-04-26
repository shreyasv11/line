classdef SolverCTMC < NetworkSolver
    % A solver based on continuous-time Markov chain (CTMC) formalism.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverCTMC(model,varargin)
            % SELF = SOLVERCTMC(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function setOptions(self, options)
            % SETOPTIONS(OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        function supported = getSupported(self,supported)
            % SUPPORTED = GETSUPPORTED(SELF,SUPPORTED)
            
            if ~exist('supported','var')
                supported=struct();
            end
        end
        
        function runtime = run(self)
            % RUNTIME = RUN()
            % Run the solver
            
            T0=tic;
            
            options = self.getOptions;
            
            if ~isinf(options.timespan(1)) && (options.timespan(1) == options.timespan(2))
                warning('%s: timespan is a single point, spacing by options.tol (%e).\n',mfilename, options.tol);
                options.timespan(2) = options.timespan(1) + options.tol;
            end
            
            Solver.resetRandomGeneratorSeed(options.seed);
            
            if ~self.supports(self.model)
                %                if options.verbose
                error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
                %                end
                %                runtime = toc(T0);
                %                return
            end
            
            qn = self.getStruct();
            if any(isinf(qn.njobs))
                if isinf(options.cutoff)
                    error('Line:UnspecifiedOption','The model has open chains, it is mandatory to specify a finite cutoff value, e.g., SolverCTMC(model,''cutoff'',1).');
                end
            end
            
            M = qn.nstations;
            K = qn.nclasses;
            NK = qn.njobs;
            sizeEstimator = 0;
            for k=1:K
                sizeEstimator = sizeEstimator + gammaln(1+NK(k)+M-1) - gammaln(1+M-1) - gammaln(1+NK(k)); % worst-case estimate of the state space
            end
            if sizeEstimator > 6
                if ~isfield(options,'force') || options.force == false
                    error('Line:ModelTooLargeToSolve','CTMC size may be too large to solve. Stopping SolverCTMC. Set options.force=true to bypass this control.\n');
                    runtime=toc(T0);
                    return
                end
            end
            
            % we compute all metrics anyway because CTMC has essentially
            % the same cost
            if isinf(options.timespan(1))
                [QN,UN,RN,TN,CN,XN,Q,SS,SSq,Dfilt] = solver_ctmc_analysis(qn, options);
                %qn.space = SS;
                self.result.infGen = Q;
                self.result.space = SS;
                self.result.spaceAggr = SSq;
                self.result.eventFilt = Dfilt;
                runtime=toc(T0);
                self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime);
            else
                lastSol= [];
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
                        [t,pit,QNt,UNt,~,TNt,~,~,Q,SS,SSq,Dfilt,runtime_t] = solver_ctmc_transient_analysis(qn, options);
                        self.result.space = SS;
                        self.result.spaceAggr = SSq;
                        self.result.infGen = Q;
                        self.result.eventFilt = Dfilt;
                        qn.space = SS;
                        setTranProb(self,t,pit,SS,runtime_t);
                        if isempty(self.result) || ~isfield(self.result,'Tran') || ~isfield(self.result.Tran,'Avg') || ~isfield(self.result.Tran.Avg,'Q')
                            self.result.Tran.Avg.Q = cell(M,K);
                            self.result.Tran.Avg.U = cell(M,K);
                            self.result.Tran.Avg.T = cell(M,K);
                            for i=1:M
                                for r=1:K
                                    self.result.Tran.Avg.Q{i,r} = [QNt{i,r} * s0prior_val,t];
                                    self.result.Tran.Avg.U{i,r} = [UNt{i,r} * s0prior_val,t];
                                    self.result.Tran.Avg.T{i,r} = [TNt{i,r} * s0prior_val,t];
                                end
                            end
                        else
                            for i=1:M
                                for r=1:K
                                    tunion = union(self.result.Tran.Avg.Q{i,r}(:,2), t);
                                    dataOld = interp1(self.result.Tran.Avg.Q{i,r}(:,2),self.result.Tran.Avg.Q{i,r}(:,1),tunion);
                                    dataNew = interp1(t,QNt{i,r},tunion);
                                    self.result.Tran.Avg.Q{i,r} = [dataOld+s0prior_val*dataNew,tunion];
                                    dataOld = interp1(self.result.Tran.Avg.U{i,r}(:,2),self.result.Tran.Avg.U{i,r}(:,1),tunion);
                                    dataNew = interp1(t,UNt{i,r},tunion);
                                    self.result.Tran.Avg.U{i,r} = [dataOld+s0prior_val*dataNew,tunion];
                                    
                                    dataOld = interp1(self.result.Tran.Avg.T{i,r}(:,2),self.result.Tran.Avg.T{i,r}(:,1),tunion);
                                    dataNew = interp1(t,TNt{i,r},tunion);
                                    self.result.Tran.Avg.T{i,r} = [dataOld+s0prior_val*dataNew,tunion];
                                end
                            end
                        end
                    end
                    s0_id=pprod(s0_id,s0_sz-1); % update initial state
                end
                runtime = toc(T0);
                self.result.('solver') = self.getName();
                self.result.runtime = runtime;
                self.result.solverSpecific = lastSol;
            end
        end
        
        function Pnir = getProbState(self, node, state)
            % PNIR = GETPROBSTATE(NODE, STATE)
            
            if ~exist('node','var')
                error('getProbState requires to pass a parameter the station of interest.');
            end
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            qn.state = self.model.getState;
            if exist('state','var')
                qn.state{node} = state;
            end
            ind = self.model.getNodeIndex(node);
            for isf=1:length(qn.state)
                isf_param = qn.nodeToStateful(ind);
                if isf ~= isf_param
                    qn.state{isf} = qn.state{isf}*0 -1;
                end
            end
            Pnir = solver_ctmc_marg(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.marginal = Pnir;
            runtime = toc(T0);
            self.result.runtime = runtime;
            Pnir = Pnir(node);
        end
        
        function Pn = getProbSysState(self)
            % PN = GETPROBSYSSTATE()
            
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            if self.model.isStateValid
                Pn = solver_ctmc_joint(qn, self.options);
                self.result.('solver') = self.getName();
                self.result.Prob.joint = Pn;
            else
                error('The model state is invalid.');
            end
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function Pnir = getProbStateAggr(self, ist)
            % PNIR = GETPROBSTATEAGGR(IST)
            
            if ~exist('ist','var')
                error('getProbState requires to pass a parameter the station of interest.');
            end
            if ist > self.model.getNumberOfStations
                error('Station number exceeds the number of stations in the model.');
            end
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            qn.state = self.model.getState;
            
            if isempty(self.result) || ~isfield(self.result,'Prob') || ~isfield(self.result.Prob,'marginal')
                Pnir = solver_ctmc_margaggr(qn, self.options);
                self.result.('solver') = self.getName();
                self.result.Prob.marginal = Pnir;
            else
                Pnir = self.result.Prob.marginal;
            end
            runtime = toc(T0);
            self.result.runtime = runtime;
            Pnir = Pnir(ist);
        end
        
        function Pn = getProbSysStateAggr(self)
            % PN = GETPROBSYSSTATEAGGR()
            
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            if self.model.isStateValid
                Pn = solver_ctmc_jointaggr(qn, self.options);
                self.result.('solver') = self.getName();
                self.result.Prob.joint = Pn;
            else
                error('The model state is invalid.');
            end
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function [Pi_t, SSsysa] = getTranProbSysStateAggr(self)
            % [PI_T, SSSYSA] = GETTRANPROBSYSSTATEAGGR()
            
            options = self.getOptions;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                qn = self.getStruct;
                [t,pi_t,~,~,~,~,~,~,~,~,~,SSsysa] = solver_ctmc_transient_analysis(qn, options);
                Pi_t = [t, pi_t];
            else
                error('getTranProbSysStateAggr in SolverCTMC requires to specify a finite timespan T, e.g., SolverCTMC(model,''timespan'',[0,T]).');
            end
        end
        
        function [Pi_t, SSnode_a] = getTranProbStateAggr(self, node)
            % [PI_T, SSNODE_A] = GETTRANPROBSTATEAGGR(NODE)
            
            options = self.getOptions;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                qn = self.getStruct;
                [t,pi_t,~,~,~,~,~,~,~,~,~,SSa] = solver_ctmc_transient_analysis(qn, options);
                jnd = self.model.getNodeIndex(node);
                SSnode_a = SSa(:,(jnd-1)*qn.nclasses+1:jnd*qn.nclasses);
                Pi_t = [t, pi_t];
            else
                error('getTranProbStateAggr in SolverCTMC requires to specify a finite timespan T, e.g., SolverCTMC(model,''timespan'',[0,T]).');
            end
        end
        
        function [Pi_t, SSsys] = getTranProbSysState(self)
            % [PI_T, SSSYS] = GETTRANPROBSYSSTATE()
            
            options = self.getOptions;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                qn = self.getStruct;
                [t,pi_t,~,~,~,~,~,~,~,~,SSsys]  = solver_ctmc_transient_analysis(qn, options);
                Pi_t = [t, pi_t];
            else
                error('getTranProbSysState in SolverCTMC requires to specify a finite timespan T, e.g., SolverCTMC(model,''timespan'',[0,T]).');
            end
        end
        
        function [Pi_t, SSnode] = getTranProbState(self, node)
            % [PI_T, SSNODE] = GETTRANPROBSTATE(NODE)
            
            options = self.getOptions;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                qn = self.getStruct;
                [t,pi_t,~,~,~,~,~,~,~,~,SS] = solver_ctmc_transient_analysis(qn, options);
                jnd = self.model.getNodeIndex(node);
                shift = 1;
                for isf = 1:qn.nstateful
                    len = length(qn.state{isf});
                    if qn.statefulToNode(isf) == jnd
                        SSnode = SS(:,shift:shift+len-1);
                        break;
                    end
                    shift = shift+len;
                end
                Pi_t = [t, pi_t];
            else
                error('getTranProbState in SolverCTMC requires to specify a finite timespan T, e.g., SolverCTMC(model,''timespan'',[0,T]).');
            end
        end
        
        function stateSpace = getStateSpace(self)
            % STATESPACE = GETSTATESPACE()
            
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'space')
                warning('The model has not been solved yet. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getStateSpace()');
                stateSpace = [];
            else
                stateSpace = self.result.space;
            end
        end
        
        function stateSpaceAggr = getStateSpaceAggr(self)
            % STATESPACEAGGR = GETSTATESPACEAGGR()
            
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'spaceAggr')
                warning('The model has not been solved yet. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getStateSpaceAggr()');
                stateSpaceAggr = [];
            else
                stateSpaceAggr = self.result.spaceAggr;
            end
        end
        
        function [infGen, eventFilt] = getGenerator(self)
            % [INFGEN, EVENTFILT] = GETGENERATOR()
            
            % [infGen, eventFilt] = getGenerator(self)
            % returns the infinitesimal generator of the CTMC and the
            % associated filtration for each event
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'infGen')
                warning('The model has not been solved yet. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getGenerator()');
                infGen = [];
                eventFilt = [];
            else
                infGen = self.result.infGen;
                eventFilt = self.result.eventFilt;
            end
            
        end
        
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Source','Sink',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_GPS',...
                'SchedStrategy_RAND','SchedStrategy_SEPT',...
                'SchedStrategy_LEPT','SchedStrategy_FCFS',...
                'SchedStrategy_HOL','SchedStrategy_LCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'ClosedClass','OpenClass','Replayer'});
        end
        
        function [bool, featSupported, featUsed] = supports(model)
            % [BOOL, FEATSUPPORTED, FEATUSED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverCTMC.getFeatureSet();
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
            options.timespan = [Inf,Inf];
        end
        
        function printInfGen(Q,SS)
            % PRINTINFGEN(Q,SS)
            
            SS=full(SS);
            Q=full(Q);
            for s=1:size(SS,1)
                for sp=1:size(SS,1)
                    if Q(s,sp)>0
                        fprintf(1,'%s->%s: %f\n',mat2str(SS(s,:)),mat2str(SS(sp,:)),double(Q(s,sp)));
                    end
                end
            end
        end
        
        function printEventFilt(sync,D,SS,myevents)
            % PRINTEVENTFILT(SYNC,D,SS,MYEVENTS)
            
            if ~exist('events','var')
                myevents = 1:length(sync);
            end
            SS=full(SS);
            for e=myevents
                D{e}=full(D{e});
                for s=1:size(SS,1)
                    for sp=1:size(SS,1)
                        if D{e}(s,sp)>0
                            fprintf(1,'%s-- %d: (%d,%d) => (%d,%d) -->%s: %f\n',mat2str(SS(s,:)),e,sync{e}.active{1}.node,sync{e}.active{1}.class,sync{e}.passive{1}.node,sync{e}.passive{1}.class,mat2str(SS(sp,:)),double(D{e}(s,sp)));
                        end
                    end
                end
            end
        end
    end
end
