classdef SolverJMT < NetworkSolver
    % A solver that interfaces the Java Modelling Tools (JMT) to LINE.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    %Private properties
    properties %(GetAccess = 'private', SetAccess='private')
        jmtPath;
        filePath;
        fileName;
        maxSamples;
        seed;
    end
    
    %Constants
    properties (Constant)
        xmlnsXsi = 'http://www.w3.org/2001/XMLSchema-instance';
        xsiNoNamespaceSchemaLocation = 'Archive.xsd';
        fileFormat = 'jsimg';
        jsimgPath = '';
    end
    
    % PUBLIC METHODS
    methods
        
        %Constructor
        function self = SolverJMT(model, varargin)
            % SELF = SOLVERJMT(MODEL, VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if ~Solver.isJavaAvailable
                error('SolverJMT requires the java command to be available on the system path.');
            end
            if ~Solver.isAvailable
                error('SolverJMT cannot located JMT.jar in the MATLAB path.');
            end
            
            jarPath = jmtGetPath;
            self.setJMTJarPath(jarPath);
            filePath = tempdir;
            self.filePath = filePath;
            [~,fileName]=fileparts(tempname);
            self.fileName = fileName;
        end
        
        function setOptions(self, options)
            % SETOPTIONS(SELF, OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        [simDoc, section] = saveArrivalStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveBufferCapacity(self, simDoc, section, currentNode)
        [simDoc, section] = saveClassSwitchStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveDropStrategy(self, simDoc, section)
        [simDoc, section] = saveForkStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveGetStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveJoinStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveLogTunnel(self, simDoc, section, currentNode)
        [simDoc, section] = saveNumberOfServers(self, simDoc, section, currentNode)
        [simDoc, section] = savePreemptiveStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = savePreemptiveWeights(self, simDoc, section, currentNode)
        [simDoc, section] = savePutStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveRoutingStrategy(self, simDoc, section, currentNode)
        [simDoc, section] = saveServerVisits(self, simDoc, section)
        [simDoc, section] = saveServiceStrategy(self, simDoc, section, currentNode)
        [simElem, simDoc] = saveClasses(self, simElem, simDoc)
        [simElem, simDoc] = saveLinks(self, simElem, simDoc)
        [simElem, simDoc] = saveMetrics(self, simElem, simDoc)
        [simElem, simDoc] = saveXMLHeader(self, logPath)
        
        function supported = getSupported(self,supported)
            % SUPPORTED = GETSUPPORTED(SELF,SUPPORTED)
            
            if ~exist('supported','var')
                supported=struct();
            end
        end
        
        function fileName = getFileName(self)
            % FILENAME = GETFILENAME(SELF)
            
            fileName = self.fileName;
        end
        
        %Setter
        function self = setJMTJarPath(self, path)
            % SELF = SETJMTJARPATH(SELF, PATH)
            
            self.jmtPath = path;
        end
        
        % Getters
        function out = getJMTJarPath(self)
            % OUT = GETJMTJARPATH(SELF)
            
            out = self.jmtPath;
        end
        
        function out = getFilePath(self)
            % OUT = GETFILEPATH(SELF)
            
            out = self.filePath;
        end
        
        Tsim = run(self)
        
        jwatView(self, options)
        jsimgView(self, options)
        
        [outputFileName] = writeJMVA(self, outputFileName)
        [outputFileName] = writeJSIM(self, outputFileName)
        
        function [result, parsed] = getResults(self)
            % [RESULT, PARSED] = GETRESULTS(SELF)
            
            options = self.getOptions;
            switch options.method
                case {'jsim','default'}
                    [result, parsed] = self.getResultsJSIM;
                otherwise
                    [result, parsed] = self.getResultsJMVA;
            end
        end
        
        [result, parsed] = getResultsJSIM(self)
        [result, parsed] = getResultsJMVA(self)
    end
    
    %Private methods.
    methods (Access = 'private')
        function out = getJSIMTempPath(self)
            % OUT = GETJSIMTEMPPATH(SELF)
            
            fname = [self.getFileName(), ['.', 'jsimg']];
            out = [self.filePath,'jsimg',filesep, fname];
        end
        
        function out = getJMVATempPath(self)
            % OUT = GETJMVATEMPPATH(SELF)
            
            fname = [self.getFileName(), ['.', 'jmva']];
            out = [self.filePath,'jmva',filesep, fname];
        end
    end
    
    %Private methods.
    methods (Access = 'protected')
        function bool = hasAvgResults(self)
            % BOOL = HASAVGRESULTS(SELF)
            
            bool = self.hasResults();
        end
    end
    
    methods (Static)
        
        function bool = isAvailable()
            % BOOL = ISAVAILABLE()
            
            bool = true;
            if isempty(which('JMT.jar'))
                bool = false;
            end
        end
        
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink',...
                'Source',...
                'Router',...
                'ClassSwitch',...
                'DelayStation',...
                'Queue',...
                'Fork',...
                'Join',...
                'Logger',...
                'Coxian',...
                'Cox2',...
                'APH',...
                'Erlang',...
                'Exponential',...
                'HyperExp',...
                'Det',...
                'Gamma',...
                'MMPP2',...
                'Normal',...
                'Pareto',...
                'Replayer',...
                'Uniform',...
                'StatelessClassSwitcher',...
                'InfiniteServer',...
                'SharedServer',...
                'Buffer',...
                'Dispatcher',...
                'Server',...
                'JobSink',...
                'RandomSource',...
                'ServiceTunnel',...
                'Forker',...
                'Joiner',...
                'LogTunnel',...
                'SchedStrategy_INF',...
                'SchedStrategy_PS',...
                'SchedStrategy_DPS',...
                'SchedStrategy_FCFS',...
                'SchedStrategy_GPS',...
                'SchedStrategy_RAND',...
                'SchedStrategy_HOL',...
                'SchedStrategy_LCFS',...
                'SchedStrategy_SEPT',...
                'SchedStrategy_LEPT',...
                'SchedStrategy_SJF',...
                'SchedStrategy_LJF',...
                'RoutingStrategy_PROB',...
                'RoutingStrategy_RAND',...
                'RoutingStrategy_RR',...
                'SchedStrategy_EXT',...
                'ClosedClass',...
                'OpenClass'});
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverJMT.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function jsimgOpen(filename)
            % JSIMGOPEN(FILENAME)
            
            [path] = fileparts(filename);
            if isempty(path)
                filename=[pwd,filesep,filename];
            end
            runtime = java.lang.Runtime.getRuntime();
            cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
            system(cmd);
            %runtime.exec(cmd);
        end
        
        function jsimwOpen(filename)
            % JSIMWOPEN(FILENAME)
            
            runtime = java.lang.Runtime.getRuntime();
            cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',which(filename)];
            %system(cmd);
            runtime.exec(cmd);
        end
        
        dataSet = parseLogs(model, isNodeLogged, metric);
        state = parseTranState(fileArv, fileDep, nodePreload);
        [classResT, jobResT, jobResTArvTS, classResTJobID] = parseTranRespT(fileArv, fileDep);
    end
    
    methods
        function lNormConst = getProbNormConst(self)
            % LNORMCONST = GETPROBNORMCONST(SELF)
            
            switch self.options.method
                case {'jmva','jmva.recal','jmva.comom','jmva.ls'}
                    self.run();
                    lNormConst = self.result.Prob.logNormConst;
                otherwise
                    lNormConst = NaN; %#ok<NASGU>
                    error('Selected solver method does not compute normalizing constants. Choose either jmva.recal, jmva.comom, or jmva.ls.');
            end
        end
        
        %% StateAggr methods
        
        function Pr = getProbStateAggr(self, node, state_a)
            % PR = GETPROBSTATEAGGR(SELF, NODE, STATE_A)
            
            if ~exist('state_a','var')
                state_a = self.model.getState{self.model.getStationIndex(node)};
            end
            stationStateAggr = self.getTranStateAggr(node);
            ist = self.model.getStationIndex(node);
            rows = findrows(stationStateAggr{ist}.state, state_a);
            t = stationStateAggr{ist}.t;
            dt = [t(1);diff(t)];
            Pr = sum(dt(rows))/sum(dt);
        end
        
        function sysStateAggr = getTranSysStateAggr(self)
            % SYSSTATEAGGR = GETTRANSYSSTATEAGGR(SELF)
            
            statStateAggr =  self.getTranStateAggr();
            tranSysStateAggr = cell(1,1+self.model.getNumberOfStations);
            
            tranSysStateAggr{1} = []; % timestamps
            for i=1:self.model.getNumberOfStations % stations
                tranSysStateAggr{1} = union(tranSysStateAggr{1}, statStateAggr{i}.t);
            end
            
            for i=1:self.model.getNumberOfStations % stations
                tranSysStateAggr{1+i} = [];
                [~,uniqTS] = unique(statStateAggr{i}.t);
                for j=1:self.model.getNumberOfClasses % classes
                    % we floor the interpolation as we hold the last state
                    if ~isempty(uniqTS)
                        Qijt = floor(interp1(statStateAggr{i}.t(uniqTS), statStateAggr{i}.state(uniqTS,j), tranSysStateAggr{1}));
                        if isnan(Qijt(end))
                            Qijt(end)=Qijt(end-1);
                        end
                        tranSysStateAggr{1+i} = [tranSysStateAggr{1+i}, Qijt];
                    else
                        Qijt = NaN*ones(length(tranSysStateAggr{1}),1);
                        tranSysStateAggr{1+i} = [tranSysStateAggr{1+i}, Qijt];
                    end
                end
            end
            sysStateAggr = SystemStateAggr(self.model, tranSysStateAggr);
        end
        
        function ProbSysStateAggr = getProbSysStateAggr(self)
            % PROBSYSSTATEAGGR = GETPROBSYSSTATEAGGR(SELF)
            
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
        
        function stationStateAggr = getTranStateAggr(self, node)
            % STATIONSTATEAGGR = GETTRANSTATEAGGR(SELF, NODE)
            
            Q = self.model.getAvgQLenHandles();
            stationStateAggr = cell(self.model.getNumberOfStations,1);
            % create a temp model
            modelCopy = self.model.copy;
            modelCopy.resetNetwork;
            
            % determine the nodes to logs
            isNodeClassLogged = false(modelCopy.getNumberOfNodes, modelCopy.getNumberOfClasses);
            for i= 1:modelCopy.getNumberOfStations
                for r=1:modelCopy.getNumberOfClasses
                    if ~Q{i,r}.disabled && nargin == 1
                        ind = self.model.getNodeIndex(modelCopy.getStationNames{i});
                        isNodeClassLogged(ind,r) = true;
                    else
                        isNodeClassLogged(node,r) = true;
                    end
                end
            end
            % apply logging to the copied model
            Plinked = self.model.getLinkedRoutingMatrix();
            isNodeLogged = max(isNodeClassLogged,[],2);
            logpath = tempdir;
            modelCopy.linkAndLog(Plinked, isNodeLogged, logpath);
            % simulate the model copy and retrieve log data
            SolverJMT(modelCopy, self.getOptions).getAvg(); % log data
            logData = SolverJMT.parseLogs(modelCopy, isNodeLogged, Metric.QLen);
            
            % from here convert from nodes in logData to stations
            qn = modelCopy.getStruct;
            for ist= 1:qn.nstations
                isf = qn.stationToStateful(ist);
                t = [];
                nir = cell(1,qn.nclasses);
                for r=1:qn.nclasses
                    if ~isempty(logData{isf,r})
                        [~,uniqTS] = unique(logData{isf,r}.t);
                        if isNodeClassLogged(isf,r)
                            if ~isempty(logData{isf,r})
                                t = logData{isf,r}.t(uniqTS);
                                t = [t(2:end);t(end)];
                                nir{r} = logData{isf,r}.QLen(uniqTS);
                            end
                        end
                    else
                        nir{r} = [];
                    end
                end
                stationStateAggr{ist} = StationStateAggr(self.model.stations{ist},t,cell2mat(nir));
            end
        end
        
        %% Cdf methods
        
        function RD = getCdfRespT(self, R)
            % RD = GETCDFRESPT(SELF, R)
            
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles();
            end
            RD = cell(self.model.getNumberOfStations, self.model.getNumberOfClasses);
            QN = self.getAvgQLen(); % steady-state qlen
            qn = self.getStruct;
            n = QN;
            for r=1:qn.nclasses
                if isinf(qn.njobs(r))
                    n(:,r) = floor(QN(:,r));
                else
                    n(:,r) = floor(QN(:,r));
                    if sum(n(:,r)) < qn.njobs(r)
                        imax = maxpos(n(:,r)); % put jobs on the bottleneck
                        n(imax,r) = qn.njobs(r) - sum(n(:,r));
                    end
                end
            end
            cdfmodel = self.model.copy;
            %            cdfmodel.resetNetwork;
            cdfmodel.initFromMarginal(n);
            isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
            for i= 1:cdfmodel.getNumberOfStations
                for r=1:cdfmodel.getNumberOfClasses
                    if ~R{i,r}.disabled
                        ni = self.model.getNodeIndex(cdfmodel.getStationNames{i});
                        isNodeClassLogged(ni,r) = true;
                    end
                end
            end
            Plinked = self.model.getLinkedRoutingMatrix();
            isNodeLogged = max(isNodeClassLogged,[],2);
            logpath = tempdir;
            cdfmodel.linkAndLog(Plinked, isNodeLogged, logpath);
            SolverJMT(cdfmodel, self.getOptions).getAvg(); % log data
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Metric.RespT);
            % from here convert from nodes in logData to stations
            for i= 1:cdfmodel.getNumberOfStations
                ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
                for r=1:cdfmodel.getNumberOfClasses
                    if isNodeClassLogged(ni,r)
                        if ~isempty(logData{ni,r})
                            [F,X] = ecdf(logData{ni,r}.RespT);
                            RD{i,r} = [F,X];
                        end
                    end
                end
            end
        end
        
        function RD = getTranCdfRespT(self, R)
            % RD = GETTRANCDFRESPT(SELF, R)
            
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles();
            end
            RD = cell(self.model.getNumberOfStations, self.model.getNumberOfClasses);
            cdfmodel = self.model.copy;
            cdfmodel.resetNetwork;
            isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
            for i= 1:cdfmodel.getNumberOfStations
                for r=1:cdfmodel.getNumberOfClasses
                    if ~R{i,r}.disabled
                        ni = self.model.getNodeIndex(cdfmodel.getStationNames{i});
                        isNodeClassLogged(ni,r) = true;
                    end
                end
            end
            Plinked = self.model.getLinkedRoutingMatrix();
            isNodeLogged = max(isNodeClassLogged,[],2);
            logpath = tempdir;
            cdfmodel.linkAndLog(Plinked, isNodeLogged, logpath);
            SolverJMT(cdfmodel, self.getOptions).getAvg(); % log data
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Metric.RespT);
            % from here convert from nodes in logData to stations
            for i= 1:cdfmodel.getNumberOfStations
                ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
                for r=1:cdfmodel.getNumberOfClasses
                    if isNodeClassLogged(ni,r)
                        if ~isempty(logData{ni,r})
                            [F,X] = ecdf(logData{ni,r}.RespT);
                            RD{i,r} = [F,X];
                        end
                    end
                end
            end
        end
        
        function RD = getTranCdfPassT(self, R)
            % RD = GETTRANCDFPASST(SELF, R)
            
            if ~exist('R','var')
                R = self.model.getAvgRespTHandles();
            end
            RD = cell(self.model.getNumberOfStations, self.model.getNumberOfClasses);
            cdfmodel = self.model.copy;
            cdfmodel.resetNetwork;
            isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
            for i= 1:cdfmodel.getNumberOfStations
                for r=1:cdfmodel.getNumberOfClasses
                    if ~R{i,r}.disabled
                        ni = self.model.getNodeIndex(cdfmodel.getStationNames{i});
                        isNodeClassLogged(ni,r) = true;
                    end
                end
            end
            Plinked = self.model.getLinkedRoutingMatrix();
            isNodeLogged = max(isNodeClassLogged,[],2);
            logpath = tempdir;
            cdfmodel.linkAndLog(Plinked, isNodeLogged, logpath);
            SolverJMT(cdfmodel, self.getOptions).getAvg(); % log data
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Metric.RespT);
            % from here convert from nodes in logData to stations
            for i= 1:cdfmodel.getNumberOfStations
                ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
                for r=1:cdfmodel.getNumberOfClasses
                    if isNodeClassLogged(ni,r)
                        if ~isempty(logData{ni,r})
                            [F,X] = ecdf(logData{ni,r}.RespT);
                            RD{i,r} = [F,X];
                        end
                    end
                end
            end
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
        end
    end
    
end
