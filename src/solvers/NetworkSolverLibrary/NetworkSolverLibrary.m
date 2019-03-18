classdef NetworkSolverLibrary < NetworkSolver
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    methods
        function self = NetworkSolverLibrary(model,varargin)
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if strcmp(self.getOptions.method,'default')
                error('Line:UnsupportedMethod','This solver does not have a default solution method. Used the method option to choose a solution technique.');
            end                
        end
        
        function runtime = run(self)
            T0=tic;
            options = self.getOptions;
            
            if ~self.supports(self.model)
%                if options.verbose
                    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
%                end
%                runtime = toc(T0);
%                return
            end
            
            rand('seed',options.seed);
            
            [qn] = self.model.getStruct();
            
            [Q,U,R,T,C,X] = solver_lib_analysis(qn, options);
            
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
            featSupported = NetworkSolverLibrary.getFeatureSet();
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
