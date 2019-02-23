classdef SolverNC < NetworkSolver
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    methods
        function self = SolverNC(model,varargin)
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function runtime = run(self)
            T0=tic;
            options = self.getOptions;
            if ~options.force && ~self.supports(self.model)
                if options.verbose
                    warning('This model is not supported by the %s solver. Quitting.',mfilename);
                end
                runtime = toc(T0);
                return
            end
            rand('seed',options.seed);
                        
            [qn] = self.model.getStruct();
            [Q,U,R,T,C,X,lG] = solver_nc_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
            self.result.Prob.logNormConst = lG;
        end
        
        function Pnir = getProbState(self)
            T0 = tic;
            qn = self.model.getStruct;
            % now compute marginal probability
            [Pnir,lG] = solver_nc_marg(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.logNormConst = lG;
            self.result.Prob.nir = Pnir;
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function Pnir = getProbStateSys(self)
            T0 = tic;
            qn = self.model.getStruct;
            % now compute marginal probability
            [Pnir,lG] = solver_nc_joint(qn, self.options);
            self.result.('solver') = self.getName();
            self.result.Prob.logNormConst = lG;
            self.result.Prob.nir = Pnir;
            runtime = toc(T0);
            self.result.runtime = runtime;
        end
        
        function [lNormConst] = getProbNormConst(self)            
            self.run();
            lNormConst = self.result.Prob.logNormConst;
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
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...                
                'SchedStrategy_FCFS','ClosedClass'});
        end        
        
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();    
            featSupported = SolverNC.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions()
            options = Solver.defaultOptions();
            options.samples = 1e6;
            options.timespan = [Inf,Inf];
        end
    end
end
