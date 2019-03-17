classdef SolverSSA < NetworkSolver
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    methods
        function self = SolverSSA(model,varargin)
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
            
            if ~self.supports(self.model)
%                if options.verbose
                    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver. Quitting.',mfilename);
%                end
%                runtime = toc(T0);
%                return
            end            
            
            rand('seed',options.seed);
            
            qn = self.model.getStruct();
            
            % TODO: add priors on initial state
            qn.state = self.model.getState; % not used internally by SSA
            qn.space = qn.state; % SSA progressively grows this cell array into the simulated state space
            
            [Q,U,R,T,C,X] = solver_ssa_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
        end
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Router',...
                'ClassSwitch','DelayStation','Queue',...
                'Fork','Join',...
                'Cox2','Erlang','Exponential','HyperExp',...                                                
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_FCFS',...
                'SchedStrategy_GPS','SchedStrategy_RAND',...
                'SchedStrategy_HOL','SchedStrategy_LCFS',...
                'SchedStrategy_SEPT','SchedStrategy_LEPT',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...                
                'SchedStrategy_EXT','ClosedClass','OpenClass'});
        end        
        
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();    
            featSupported = SolverSSA.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions(self)
            options = Solver.defaultOptions();
            options.timespan = [0,Inf];
			options.verbose = true;
        end
    end
end
