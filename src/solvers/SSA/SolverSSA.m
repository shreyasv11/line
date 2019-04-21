classdef SolverSSA < NetworkSolver
    % A solver based on discrete-event stochastic simulation analysis.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverSSA(model,varargin)
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        function supported = getSupported(self,supported)
            if ~exist('supported','var')
                supported=struct();
            end
        end
        
        function [runtime, tranSysState] = run(self)
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
            
            qn = self.model.getStruct();
            
            % TODO: add priors on initial state
            qn.state = self.model.getState; % not used internally by SSA
            qn.space = qn.state; % SSA progressively grows this cell array into the simulated state space
            
            [Q,U,R,T,C,X,~, tranSysState] = solver_ssa_analysis(qn, options);
            
            runtime=toc(T0);
            self.setAvgResults(Q,U,R,T,C,X,runtime);
        end
        
        function ProbState = getProbState(self, node, state)
            % we do not use probSysState as that is for joint states
            [~, tranSysState] = self.run;
            isf = self.model.getStatefulNodeIndex(node);
            TSS = cell2mat({tranSysState{1},tranSysState{1+isf}});    
            TSS(:,1)=[TSS(1,1);diff(TSS(:,1))];
            if ~exist('state','var')
                state = self.model.getState{isf};
            end
            rows = findrows(TSS(:,2:end), state);            
            if ~isempty(rows)
                ProbState = sum(TSS(rows,1))/sum(TSS(:,1));
            else
                warning('The state was not seen during the simulation.');
                ProbState = 0;
            end
        end
        
        function ProbStateAggr = getProbStateAggr(self, node, state)
            % we do not use probSysState as that is for joint states
            TranSysStateAggr = self.getTranSysStateAggr;
            isf = self.model.getStatefulNodeIndex(node);
            TSS = cell2mat({TranSysStateAggr.t,TranSysStateAggr.state{isf}});            
            TSS(:,1)=[TSS(1,1);diff(TSS(:,1))];
            if ~exist('state','var')
                state = self.model.getState{isf};
            end
            rows = findrows(TSS(:,2:end), state);            
            if ~isempty(rows)
                ProbStateAggr = sum(TSS(rows,1))/sum(TSS(:,1));
            else
                warning('The state was not seen during the simulation.');
                ProbStateAggr = 0;
            end
        end        
        
        function ProbSysState = getProbSysState(self)
            TranSysState = self.getTranSysState;
            TSS = cell2mat([TranSysState.t,TranSysState.state(:)']);            
            TSS(:,1)=[TSS(1,1);diff(TSS(:,1))];
            state = cell2mat(self.model.getState');
            rows = findrows(TSS(:,2:end), state);
            if ~isempty(rows)
                ProbSysState = sum(TSS(rows,1))/sum(TSS(:,1));
            else
                warning('The state was not seen during the simulation.');
                ProbSysState = 0;
            end         
        end
        
        function ProbSysStateAggr = getProbSysStateAggr(self)
            TranSysStateAggr = self.getTranSysStateAggr;
            TSS = cell2mat([TranSysStateAggr.t,TranSysStateAggr.state(:)']);            
            TSS(:,1)=[TSS(1,1);diff(TSS(:,1))];
            state = self.model.getState;
            qn = self.model.getStruct;
            nir = zeros(qn.nstateful,qn.nclasses);
            for isf=1:qn.nstateful
                ind = qn.statefulToNode(isf);
                [~,nir(isf,:)] = State.toMarginal(qn, ind, state{isf});
            end            
            nir = nir';
            rows = findrows(TSS(:,2:end), nir(:)');
            if ~isempty(rows)
                ProbSysStateAggr = sum(TSS(rows,1))/sum(TSS(:,1));
            else
                warning('The state was not seen during the simulation.');
                ProbSysStateAggr = 0;
            end
        end
        
        function TranNodeState = getTranState(self, node)
            options = self.getOptions;
            switch options.method
                case {'default','serial'}
                    [~, tranSystemState] = self.run;
                    tranNodeState = cell(1,2);
                    isf = self.model.getStatefulNodeIndex(node);
                    tranNodeState{1} = tranSystemState{1};
                    tranNodeState{2} = tranSystemState{1+isf};
                    TranNodeState = NodeState(node,tranNodeState);
                otherwise
                    error('getTranSysState is not available in SolverSSA with the chosen method.');
            end
        end
        
        function TranNodeStateAggr = getTranStateAggr(self, node)
            options = self.getOptions;
            switch options.method
                case {'default','serial'}
                    [~, tranSystemState] = self.run;
                    qn = self.model.getStruct;
                    tranNodeState = cell(1,2);
                    isf = self.model.getStatefulNodeIndex(node);
                    tranNodeState{1} = tranSystemState{1};
                    [~,nir]=State.toMarginal(qn,qn.statefulToNode(isf),tranSystemState{1+isf});
                    tranNodeState{2} = nir;
                    TranNodeStateAggr = NodeState(node,tranNodeState);
                otherwise
                    error('getTranSysState is not available in SolverSSA with the chosen method.');
            end
        end
        
        function TranSysStateAggr = getTranSysStateAggr(self)
            options = self.getOptions;
            switch options.method
                case {'default','serial'}
                    [~, tranSystemState] = self.run;                    
                    qn = self.model.getStruct;
                    for ist=1:self.model.getNumberOfStations
                        isf = qn.stationToStateful(ist);
                        [~,nir]=State.toMarginal(qn,qn.stationToNode(ist),tranSystemState{1+isf});
                        tranSystemState{1+ist} = nir;
                    end
                    TranSysStateAggr = SystemStateAggr(self.model, tranSystemState);
                otherwise
                    error('getTranSysState is not available in SolverSSA with the chosen method.');
            end
        end
        
        function TranSysState = getTranSysState(self)
            options = self.getOptions;
            switch options.method
                case {'default','serial'}
                    [~, tranSystemState] = self.run;
                    TranSysState = SystemState(self.model, tranSystemState);
                otherwise
                    error('getTranSysState is not available in SolverSSA with the chosen method.');
            end
        end
    end
    
    methods (Static)
        %                'Fork','Join','Forker','Joiner',...
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Router',...
                'ClassSwitch','DelayStation','Queue',...
                'Coxian','Erlang','Exponential','HyperExp',...
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
