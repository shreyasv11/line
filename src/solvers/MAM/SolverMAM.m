classdef SolverMAM < NetworkSolver
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    methods
        function self = SolverMAM(model,varargin)
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function runtime = run(self)
            T0=tic;
            options=self.options;
            
            options = self.getOptions;
            
            if ~options.force && ~self.supports(self.model)
                if options.verbose
                    warning('This model is not supported by the %s solver. Quitting.',mfilename);
                end
                runtime = toc(T0);
                return
            end
            
            rng(options.seed,'twister');
            
            [qn] = self.model.getStruct();
            
            [Q,U,R,T,C,X] = solver_mam_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
        end
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'SchedStrategy_HOL','SchedStrategy_FCFS','OpenClass','Replayer'});
        end        
        
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();    
            featSupported = SolverMAM.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions()
            options = Solver.defaultOptions();
            options.timespan = [Inf,Inf];
        end
    end
end
