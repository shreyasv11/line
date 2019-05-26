classdef SolverCTMC < NetworkSolver
    % A solver based on continuous-time Markov chain (CTMC) formalism.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverCTMC(model,varargin)
            % SELF = SOLVERCTMC(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
        end
        
        runtime = run(self, options)
        Pnir = getProb(self, node, state)
        Pn = getProbSys(self)
        Pnir = getProbAggr(self, ist)
        
        Pn = getProbSysAggr(self)
        [Pi_t, SSsysa] = getTranProbSysAggr(self)   
        [Pi_t, SSnode_a] = getTranProbAggr(self, node)
        [Pi_t, SSsys] = getTranProbSys(self)     
        [Pi_t, SSnode] = getTranProb(self, node)
        
        function stateSpace = getStateSpace(self)
            % STATESPACE = GETSTATESPACE()
            
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'space')
                warning('The model has not been cached. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getStateSpace()');
                stateSpace = [];
            else
                stateSpace = self.result.space;
            end
        end
        
        function stateSpaceAggr = getStateSpaceAggr(self)
            % STATESPACEAGGR = GETSTATESPACEAGGR()
            
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'spaceAggr')
                warning('The model has not been cached. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getStateSpaceAggr()');
                stateSpaceAggr = [];
            else
                stateSpaceAggr = self.result.spaceAggr;
            end
        end
        
        function [infGen, eventFilt] = getGenerator(self)
            % [INFGEN, EVENTFILT] = GETGENERATOR()
            
            % [infGen, eventFilt] = getGenerator(self)
            % returns the infinitesimal generator of the CTMC and the
            % associated filtration for each event
            options = self.getOptions;
            if options.force
                self.run;
            end
            if isempty(self.result) || ~isfield(self.result,'infGen')
                warning('The model has not been cached. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getGenerator()');
                infGen = [];
                eventFilt = [];
            else
                infGen = self.result.infGen;
                eventFilt = self.result.eventFilt;
            end
            
        end
        
        tstate = sampleSys(self, numevents);
        sampleAggr = sampleAggr(self, node, numSamples);
        
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Source','Sink',...
                'ClassSwitch','DelayStation','Queue',...
                'APH','Coxian','Erlang','Exponential','HyperExp',...
                'StatelessClassSwitcher','InfiniteServer','SharedServer','Buffer','Dispatcher',...
                'Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_INF','SchedStrategy_PS',...
                'SchedStrategy_DPS','SchedStrategy_GPS',...
                'SchedStrategy_RAND','SchedStrategy_SEPT',...
                'SchedStrategy_LEPT','SchedStrategy_FCFS',...
                'SchedStrategy_HOL','SchedStrategy_LCFS',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'ClosedClass','OpenClass','Replayer'});
        end
        
        function [bool, featSupported, featUsed] = supports(model)
            % [BOOL, FEATSUPPORTED, FEATUSED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverCTMC.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
        
        function checkOptions(options)
            % CHECKOPTIONS(OPTIONS)
            
            % do nothing
        end
        
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('CTMC');
        end
        
        function printInfGen(Q,SS)
            % PRINTINFGEN(Q,SS)
            
            SS=full(SS);
            Q=full(Q);
            for s=1:size(SS,1)
                for sp=1:size(SS,1)
                    if Q(s,sp)>0
                        fprintf(1,'%s->%s: %f\n',mat2str(SS(s,:)),mat2str(SS(sp,:)),double(Q(s,sp)));
                    end
                end
            end
        end
        
        function printEventFilt(sync,D,SS,myevents)
            % PRINTEVENTFILT(SYNC,D,SS,MYEVENTS)
            
            if ~exist('events','var')
                myevents = 1:length(sync);
            end
            SS=full(SS);
            for e=myevents
                D{e}=full(D{e});
                for s=1:size(SS,1)
                    for sp=1:size(SS,1)
                        if D{e}(s,sp)>0
                            fprintf(1,'%s-- %d: (%d,%d) => (%d,%d) -->%s: %f\n',mat2str(SS(s,:)),e,sync{e}.active{1}.node,sync{e}.active{1}.class,sync{e}.passive{1}.node,sync{e}.passive{1}.class,mat2str(SS(sp,:)),double(D{e}(s,sp)));
                        end
                    end
                end
            end
        end
    end
end
