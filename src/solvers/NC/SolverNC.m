classdef SolverNC < NetworkSolver
    % A solver based on normalizing constant methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverNC(model,varargin)
            % SELF = SOLVERNC(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function setOptions(self, options)
            % SETOPTIONS(OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        function runtime = run(self)
            % RUNTIME = RUN()
            % Run the solver
            
            T0=tic;
            options = self.getOptions;
            if ~self.supports(self.model)
                %                if options.verbose
                error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
                %                end
                %                runtime = toc(T0);
                %                return
            end
            Solver.resetRandomGeneratorSeed(options.seed);
            
            [qn] = self.model.getStruct();
            [Q,U,R,T,C,X,lG] = solver_nc_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
            self.result.Prob.logNormConst = lG;
        end
        
        function Pnir = getProbStateAggr(self, node, state_a)
            % PNIR = GETPROBSTATEAGGR(NODE, STATE_A)
            
            if ~exist('state_a','var')
                state_a = self.model.getState{self.model.getStatefulNodeIndex(node)};
            end
            T0 = tic;
            qn = self.model.getStruct;
            % now compute marginal probability
            ist = self.model.getStationIndex(node);
            qn.state{ist} = state_a;
            [Pnir,lG] = solver_nc_marg(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.logNormConst = lG;
            self.result.Prob.marginal = Pnir;
            runtime = toc(T0);
            self.result.runtime = runtime;
            Pnir = Pnir(ist);
        end
        
        function Pn = getProbSysState(self)
            % PN = GETPROBSYSSTATE()
            
            T0 = tic;
            qn = self.model.getStruct;
            % now compute marginal probability
            [Pn,lG] = solver_nc_joint(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.logNormConst = lG;
            self.result.Prob.joint = Pn;
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function Pn = getProbSysStateAggr(self)
            % PN = GETPROBSYSSTATEAGGR()
            
            T0 = tic;
            qn = self.model.getStruct;
            % now compute marginal probability
            [Pn,lG] = solver_nc_jointaggr(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.logNormConst = lG;
            self.result.Prob.joint = Pn;
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function [lNormConst] = getProbNormConst(self)
            % [LNORMCONST] = GETPROBNORMCONST()
            
            self.run();
            lNormConst = self.result.Prob.logNormConst;
        end
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'SchedStrategy_FCFS','ClosedClass'});
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverNC.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
        
    end
    
    methods (Static)
        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)
            
            solverName = mfilename;
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                error('Finite timespan not supported in %s',solverName);
            end
        end
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            
            options = Solver.defaultOptions();
            options.samples = 1e6;
            options.timespan = [Inf,Inf];
        end
    end
end
