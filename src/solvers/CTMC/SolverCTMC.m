classdef SolverCTMC < NetworkSolver
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    methods
        function self = SolverCTMC(model,varargin)
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function supported = getSupported(self,supported)
            if ~exist('supported','var')
                supported=struct();
            end
        end
                
        function runtime = run(self)
            T0=tic;
            
            options = self.getOptions;
            
            if ~isinf(options.timespan(1)) && (options.timespan(1) == options.timespan(2))
                warning('%s: timespan is a single point, spacing by options.tol (%e).\n',mfilename, options.tol);
                options.timespan(2) = options.timespan(1) + options.tol;
            end
            rng(options.seed,'twister');
            
            if ~options.force && ~self.supports(self.model)
                if options.verbose
                    warning('This model is not supported by the %s solver. Quitting.',mfilename);
                end
                runtime = toc(T0);
                return
            end
            
            qn = self.getStruct();
            if any(isinf(qn.njobs))
                if isinf(options.cutoff)
                    error('The model has open chains, it is mandatory to specify a finite cutoff value, e.g., SolverCTMC(model,''cutoff'',1).');
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
                if ~isfield(options,'force') || options.force == 0
                    fprintf(1,'CTMC size may be too large to solve. Stopping SolverCTMC. Set options.force=1 to bypass this control.\n');
                    runtime=toc(T0);
                    return
                end
            end
            
            % we compute all metrics anyway because CTMC has essentially
            % the same cost
            if isinf(options.timespan(1))
                [Q,U,R,T,C,X,~,fname] = solver_ctmc_analysis(qn, options);
                runtime=toc(T0);
                self.setAvgResults(Q,U,R,T,C,X,runtime);
                self.result.kept_model = fname;
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
                        [t,Qfull_t,Ufull_t,~,Tfull_t,~,~,~,~] = solver_ctmc_transient_analysis(qn, options);
                        if isempty(self.result) || ~isfield(self.result,'TranAvg') || ~isfield(self.result.TranAvg,'Q')
                            self.result.TranAvg.Q = cell(M,K);
                            self.result.TranAvg.U = cell(M,K);
                            self.result.TranAvg.T = cell(M,K);
                            for i=1:M
                                for r=1:K
                                    self.result.TranAvg.Q{i,r} = [Qfull_t{i,r} * s0prior_val,t];
                                    self.result.TranAvg.U{i,r} = [Ufull_t{i,r} * s0prior_val,t];
                                    self.result.TranAvg.T{i,r} = [Tfull_t{i,r} * s0prior_val,t];
                                end
                            end
                        else
                            for i=1:M
                                for r=1:K
                                    tunion = union(self.result.TranAvg.Q{i,r}(:,2), t);
                                    dataOld = interp1(self.result.TranAvg.Q{i,r}(:,2),self.result.TranAvg.Q{i,r}(:,1),tunion);
                                    dataNew = interp1(t,Qfull_t{i,r},tunion);
                                    self.result.TranAvg.Q{i,r} = [dataOld+s0prior_val*dataNew,tunion];
                                    
                                    dataOld = interp1(self.result.TranAvg.U{i,r}(:,2),self.result.TranAvg.U{i,r}(:,1),tunion);
                                    dataNew = interp1(t,Ufull_t{i,r},tunion);
                                    self.result.TranAvg.U{i,r} = [dataOld+s0prior_val*dataNew,tunion];
                                    
                                    dataOld = interp1(self.result.TranAvg.T{i,r}(:,2),self.result.TranAvg.T{i,r}(:,1),tunion);
                                    dataNew = interp1(t,Tfull_t{i,r},tunion);
                                    self.result.TranAvg.T{i,r} = [dataOld+s0prior_val*dataNew,tunion];
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
            
        function Pnir = getProbState(self)
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            qn.state = self.model.getState;
            Pnir = solver_ctmc_marg(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.nir = Pnir;
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function Pnir = getProbStateSys(self)
            if ~isfield(self.options,'keep')
                self.options.keep = false;
            end
            T0 = tic;
            qn = self.model.getStruct;
            if self.model.isStateValid 
                Pnir = solver_ctmc_joint(qn, self.options);
                self.result.('solver') = self.getName();
                self.result.Prob.nir = Pnir;
            end
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitch','InfiniteServer','SharedServer','Buffer','Dispatcher',...
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
            featUsed = model.getUsedLangFeatures();    
            featSupported = SolverCTMC.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions()
            options = Solver.defaultOptions();
            options.timespan = [Inf,Inf];
        end
        
        function printInfGen(Q,SS)
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
        
        function printEventFilt(sync,D,SS,events)
            if ~exist('events','var')
                events = 1:length(sync);
            end
            SS=full(SS);
            for e=events
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
