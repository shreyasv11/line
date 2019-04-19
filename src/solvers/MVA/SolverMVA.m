classdef SolverMVA < NetworkSolver
    % A solver implementing mean-value analysis (MVA) methods.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverMVA(model,varargin)
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function runtime = run(self)
            T0=tic;
            options = self.getOptions;
            if ~self.supports(self.model)
                error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
            end
            Solver.resetRandomGeneratorSeed(options.seed);
            
            [qn] = self.model.getStruct();
            
            if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
                error('The exact method requires the model to have a product-form solution. This model does not have one. You can use the Network method hasProductFormSolution() to check in advance.');
            end
            
            [Q,U,R,T,C,X,lG,runtime] = solver_mva_analysis(qn, options);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
            self.result.Prob.logNormConst = lG;
        end
        
        function [lNormConst] = getProbNormConst(self)
            if ~isempty(self.result)
                lNormConst = self.result.Prob.logNormConst;
            else
                optnc = self.options;
                optnc.method = 'exact';
                [~,~,~,~,~,~,lNormConst] = solver_mva_analysis(self.getStruct, optnc);
                self.result.Prob.logNormConst = lNormConst;
            end
        end
        
        function [Pnir,logPnir] = getProbStateAggr(self, ist)
            if ~exist('ist','var')
                error('getProbStateAggr requires to pass a parameter the station of interest.');
            end
            if ist > self.model.getNumberOfStations
                error('Station number exceeds the number of stations in the model.');
            end
            if isempty(self.result)
                self.run;
            end
            Q = self.result.Avg.Q;
            qn = self.model.getStruct;
            N = qn.njobs;
            if all(isfinite(N))
                state = self.model.getState{qn.stationToStateful(ist)};
                [~, nir, ~, ~] = State.toMarginal(qn, ist, state, self.getOptions);
                % Binomial approximation with mean fitted to queue-lengths.
                % Rainer Schmidt, "An approximate MVA ...", PEVA 29:245-254, 1997.
                logPnir = 0;
                for r=1:size(nir,2)
                    logPnir = logPnir + nchoosekln(N(r),nir(r));
                    logPnir = logPnir + nir(r)*log(Q(ist,r)/N(r));
                    logPnir = logPnir + (N(r)-nir(r))*log(1-Q(ist,r)/N(r));
                end
                Pnir = real(exp(logPnir));
            else
                error('getProbStateAggr not yet implemented for models with open classes.');
            end
        end
        
        function [Pnir,logPn] = getProbSysStateAggr(self)
            if isempty(self.result)
                self.run;
            end
            Q = self.result.Avg.Q;
            qn = self.model.getStruct;
            N = qn.njobs;
            if all(isfinite(N))
                state = self.model.getState;
                % Binomial approximation with mean fitted to queue-lengths.
                % Rainer Schmidt, "An approximate MVA ...", PEVA 29:245-254, 1997.
                logPn = sum(factln(N));
                for ist=1:qn.nstations
                    [~, nir, ~, ~] = State.toMarginal(qn, ist, state{ist}, self.getOptions);
%                    logPn = logPn - log(sum(nir));
                    for r=1:qn.nclasses
                        logPn = logPn - factln(nir(r));
                        if Q(ist,r)>0
                        logPn = logPn + nir(r)*log(Q(ist,r)/N(r));
                        end
                    end
                end
                Pnir = real(exp(logPn));
            else
                error('getProbStateAggr not yet implemented for models with open classes.');
            end
        end        
        
    end
    
    methods(Static)
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
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
