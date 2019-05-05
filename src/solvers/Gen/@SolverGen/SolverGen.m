classdef SolverGen < NetworkSolver
    % Solver based on the theory of general queues (e.g., GI/G/1). The
    % solver can cope with non-Markovian arrivals and departures.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverGen(model,varargin)
            % SELF = SOLVERGEN(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        runtime = run(self);    
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'Gamma', 'Uniform', 'Det', 'Pareto', 'Replayer',  ...
                'Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...               
                'SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'OpenClass'});   
                %'StatelessClassSwitcher','ClassSwitch', ...
                % 'DelayStation','InfiniteServer',...
                % 'SharedServer', ...
                % 'SchedStrategy_INF','SchedStrategy_PS',...
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverGen.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            
            options = Solver.defaultOptions();
            options.timespan = [Inf,Inf];
        end
    end
end
