classdef SolverMVA < NetworkSolver
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

    methods
        function self = SolverMVA(model,varargin)                        
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
                        
        function runtime = run(self)
            T0=tic;
            options = self.getOptions;
            if ~self.supports(self.model)
                if options.verbose
                    warning('This model is not supported by the %s solver. Quitting.',mfilename);
                end
                runtime = toc(T0);
                return
            end
            
%            if isoctave
                rand('seed',options.seed);
%            else
%                rng(options.seed,'v4');
%            end
            
            [qn] = self.model.getStruct();
            
            if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
                error('The exact method requires the model to have a product-form solution. Quitting.');
            end            
            
            if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && self.model.hasMultiServer
                options.method = 'default';
                warning('The exact method does not support yet multi-server stations. Switching to default method.');
            end            
            
            [Q,U,R,T,C,X] = solver_amva_analysis(qn, options);            
            runtime = toc(T0);
            
            self.setAvgResults(Q,U,R,T,C,X,runtime);
        end
    end
    
    methods(Static)
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...                
                'ClosedClass','OpenClass','Replayer'});            
        end        
        
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();    
            featSupported = SolverMVA.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions(self)
            options = Solver.defaultOptions();
            options.iter_max = 10^3;
            options.iter_tol = 10^-6;
        end
    end
end
