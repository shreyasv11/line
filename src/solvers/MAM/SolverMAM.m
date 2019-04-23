classdef SolverMAM < NetworkSolver
    % A solver based on matrix-analytic methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverMAM(model,varargin)
            % SELF = SOLVERMAM(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function setOptions(self, options)
            % SETOPTIONS(SELF, OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        function runtime = run(self)
            % RUNTIME = RUN(SELF)
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
            
            [Q,U,R,T,C,X] = solver_mam_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
        end
        
        function RD = getCdfRespT(self, R)
            % RD = GETCDFRESPT(SELF, R)
            
            T0 = tic;
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles;
            end
            qn = self.getStruct;
            self.getAvg; % get steady-state solution
            options = self.getOptions;
            RD = solver_mam_passage_time(qn, qn.ph, options);
            runtime = toc(T0);
            self.setDistribResults(RD, runtime);
        end
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_FCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'OpenClass'});
            %'ClassSwitch', ...
            
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverMAM.getFeatureSet();
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
            options.timespan = [Inf,Inf];
        end
    end
end
