classdef SolverJMT < NetworkSolver
    % Copyright (c) 2012-2018, Imperial College London
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
            self = self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if ~Solver.isJavaAvailable
                error('SolverJMT requires the java command to be available on the system path. Quitting.');
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
        
        [simNode, section] = saveArrivalStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveBufferCapacity(self, simNode, section, currentNode)
        [simNode, section] = saveClassSwitchStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveDropStrategy(self, simNode, section)
        [simNode, section] = saveForkStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveGetStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveJoinStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveLogTunnel(self, simNode, section, currentNode)
        [simNode, section] = saveNumberOfServers(self, simNode, section, currentNode)
        [simNode, section] = savePreemptiveStrategy(self, simNode, section, currentNode)
        [simNode, section] = savePreemptiveWeights(self, simNode, section, currentNode)
        [simNode, section] = savePutStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveRoutingStrategy(self, simNode, section, currentNode)
        [simNode, section] = saveServerVisits(self, simNode, section)
        [simNode, section] = saveServiceStrategy(self, simNode, section, currentNode)
        [simElem, simNode] = saveClasses(self, simElem, simNode)
        [simElem, simNode] = saveLinks(self, simElem, simNode)
        [simElem, simNode] = savePerfIndexes(self, simElem, simNode)
        [simElem, simNode] = saveXMLHeader(self, logPath)
        
        function supported = getSupported(self,supported)
            if ~exist('supported','var')
                supported=struct();
            end
        end
        
        function fileName = getFileName(self)
            fileName = self.fileName;
        end
        
        %Setter
        function self = setJMTJarPath(self, path)
            self.jmtPath = path;
        end
        
        % Getters
        function out = getJMTJarPath(self)
            out = self.jmtPath;
        end
        
        function out = getFilePath(self)
            out = self.filePath;
        end
        
        Tsim = run(self)
        
        jwatView(self, options)
        jsimgView(self, options)
        
        [outputFileName] = writeJMVA(self, outputFileName)
        [outputFileName] = writeJSIM(self, outputFileName)

        function [result, parsed] = getResults(self)
            options = self.getOptions;            
            switch options.method
                case {'mva','jmva'}
                    [result, parsed] = self.getResultsJMVA;
                case {'sim','jsim','jsimg','jsimw','default'}
                    [result, parsed] = self.getResultsJSIM;
            end
        end

        [result, parsed] = getResultsJSIM(self)
        [result, parsed] = getResultsJMVA(self)
    end
    
    %Private methods.
    methods (Access = 'private')
        function out = getJSIMTempPath(self)
            fname = [self.getFileName(), ['.', 'jsimg']];
            out = [self.filePath,'jsimg',filesep, fname];
        end
        
        function out = getJMVATempPath(self)
            fname = [self.getFileName(), ['.', 'jmva']];
            out = [self.filePath,'jmva',filesep, fname];
        end
    end
    
    %Private methods.
    methods (Access = 'protected')
        function bool = hasAvgResults(self)
            bool = self.hasResults();
        end
    end
    
    methods (Static)
        function bool = isAvailable()
            bool = true;
            if isempty(which('JMT.jar'))
                bool = false;
            end
        end
        
        function featSupported = getFeatureSet()
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink',...
                'Source',...
                'Router',...
                'ClassSwitch',...
                'DelayStation',...
                'Queue',...
                'ForkStation',...
                'JoinStation',...
                'Logger',...
                'Cox2',...
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
                'StatelessClassSwitch',...
                'InfiniteServer',...
                'SharedServer',...
                'Buffer',...
                'Dispatcher',...
                'Server',...
                'JobSink',...
                'RandomSource',...
                'ServiceTunnel',...
                'Fork',...
                'Join',...
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
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverJMT.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function jsimgOpen(filename)
            [path] = fileparts(filename);
            if isempty(path)
                filename=[pwd,filesep,filename];
            end
            runtime = java.lang.Runtime.getRuntime();
            cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
            system(cmd)
            %runtime.exec(cmd);
        end
        
        function jsimwOpen(filename)
            runtime = java.lang.Runtime.getRuntime();
            cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',which(filename)];
            %system(cmd);
            runtime.exec(cmd);
        end
        
        dataSet = parseLogs(model, isNodeLogged, metric);
        state = parseTranState(fileArv, fileDep, nodePreload);
        [classResT, jobResT, jobResTArvTS, classResTJobID] = parseTranRespT(fileArv, fileDep);
        
        function options = defaultOptions()
            options = Solver.defaultOptions();
        end
    end
    
    methods
        function Pr = getProbStateSys(self)
            state = self.getTranStateSys;
            qn = self.model.getStruct;
            iat = diff(state.t);
            [unique_states,~,IC] = unique(state.nir,'rows');
            Pr = zeros(1,max(IC));
            for i=1:max(IC)
                Pr(i) = sum(iat(IC(1:end-1)==i));
            end
            Pr = Pr/sum(Pr);
            nir = [];
            state = self.model.getState;
            for i=1:self.model.getNumberOfStations
                [~, nir(i,:), ~, ~] = State.toMarginal(qn, i, state{i}, self.getOptions);
            end
            nir=nir'; nir=nir(:)'; % put as row
            Pr = Pr(matchrow(unique_states, nir));
        end
        
        function StateSys = getTranStateSys(self)
            Q = self.model.getAvgQLenHandles();
            Qsys = cell(size(Q));
            for i=1:size(Q,1)
                for j=1:size(Q,2)
                    Qsys{i,j} = Q{i,j}.copy;
                    Qsys{i,j}.disabled = false; % enable all
                end
            end
            State =  self.getTranState(Qsys);
            StateSys = struct();
            
            StateSys.t = [];
            for i=1:size(Q,1)
                for j=1:size(Q,2)
                    StateSys.t = union(StateSys.t, State{i,j}.t);
                end
            end
            
            StateSys.nir = [];
            for i=1:size(Q,1)
                for j=1:size(Q,2)
                    [~,uniqTS] = unique(State{i,j}.t);
                    % we round the interpolation to have integer states
                    Qijt = round(interp1(State{i,j}.t(uniqTS), State{i,j}.nir(uniqTS), StateSys.t));
                    StateSys.nir = [StateSys.nir, Qijt];
                end
            end
        end
        
        function State = getTranState(self, Q)
            if ~exist('Q','var')
                Q = self.model.getAvgQLenHandles();
            end
            State = cell(self.model.getNumberOfStations, self.model.getNumberOfClasses);
            cdfmodel = self.model.copy;
            cdfmodel.resetNetwork;
            isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
            for i= 1:cdfmodel.getNumberOfStations
                for r=1:cdfmodel.getNumberOfClasses
                    if ~Q{i,r}.disabled
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
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Perf.QLen);
            % from here convert from nodes in logData to stations
            for i= 1:cdfmodel.getNumberOfStations
                ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
                [~,uniqTS] = unique(logData{ni,r}.t);
                for r=1:cdfmodel.getNumberOfClasses
                    if isNodeClassLogged(ni,r)
                        if ~isempty(logData{ni,r})
                            State{i,r} = struct();
                            State{i,r}.t = logData{ni,r}.t(uniqTS);
                            State{i,r}.nir = logData{ni,r}.QLen(uniqTS);
                        end
                    end
                end
            end
        end
        
        function RD = getTranCdfRespT(self, R)
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
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Perf.RespT);
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
            logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, Perf.RespT);
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
    
    
end
