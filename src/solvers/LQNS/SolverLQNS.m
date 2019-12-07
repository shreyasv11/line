classdef SolverLQNS < LayeredNetworkSolver
    % A solver that interfaces the LQNS to LINE.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverLQNS(model, varargin)
            % SELF = SOLVERLQNS(MODEL, VARARGIN)
            
            self@LayeredNetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if ~SolverLQNS.isAvailable()
                error('SolverLQNS requires the lqns and lqsim commands to be available on the system path.');
            end
        end
        
        function runtime = run(self)
            % RUNTIME = RUN()
            % Run the solver
            
            tic;
            options = self.getOptions;
            filename = [tempname,'.lqnx'];
            try
                self.model.writeXML(filename);
                switch options.method
                    case {'default','lqns'}
                        system(['lqns -i ',num2str(options.iter_max),' -x ',filename]);
                    case {'srvn'}
                        system(['lqns -i ',num2str(options.iter_max),' -Playering=srvn -x ',filename]);
                    case {'exact'}
                        system(['lqns -i ',num2str(options.iter_max),' -Pmva=exact -x ',filename]);
                    case {'srvnexact'}
                        system(['lqns -i ',num2str(options.iter_max),' -Playering=srvn -Pmva=exact -x ',filename]);
                    case {'sim','lqsim'}
                        system(['lqsim -A ',num2str(options.samples),',3 -x ',filename]);
                    case {'lqnsdefault'}
                        system(['lqns -x ',filename]);
                    otherwise
                        system(['lqns -i ',num2str(options.iter_max),' -x ',filename]);
                end
                self.parseXMLResults(filename);
                if ~options.keep
                    [filepath,name] = fileparts(filename);
                    delete([filepath,filesep,name,'*'])
                end
            catch exception
                if ~options.keep
                    [filepath,name] = fileparts(filename);
                    delete([filepath,filesep,name,'*'])
                end
                rethrow(exception)
            end
            runtime = toc;
        end
        
        function [QN,UN,RN,TN] = getAvg(self,~,~,~,~)
            % [QN,UN,RN,TN] = GETAVG(SELF,~,~,~,~)
            
            self.run();
            QN = self.result.Avg.QLen;
            UN = self.result.Avg.Util;
            RN = self.result.Avg.RespT;
            TN = self.result.Avg.Tput;
        end
        
        function [NodeAvgTable,CallAvgTable] = getRawAvgTables(self)
            % [QN,UN,RN,TN] = GETRAWAVGTABLES(SELF,~,~,~,~)
            
            self.run();
            
            Node = self.model.lqnGraph.Nodes.Node;
            Objects = self.model.lqnGraph.Nodes.Object;
            O = length(Objects);
            NodeType = cell(O,1);
            for o = 1:O
                NodeType{o} = class(Objects{o});
            end
            Utilization = self.result.RawAvg.Nodes.Utilization;
            Phase1Utilization = self.result.RawAvg.Nodes.Phase1Utilization;
            Phase2Utilization = self.result.RawAvg.Nodes.Phase2Utilization;
            Phase1ServiceTime = self.result.RawAvg.Nodes.Phase1ServiceTime;
            Phase2ServiceTime = self.result.RawAvg.Nodes.Phase2ServiceTime;
            Throughput = self.result.RawAvg.Nodes.Throughput;
            ProcWaiting = self.result.RawAvg.Nodes.ProcWaiting;
            ProcUtilization = self.result.RawAvg.Nodes.ProcUtilization;
            NodeAvgTable = Table(Node, NodeType, Utilization, Phase1Utilization,...
                Phase2Utilization, Phase1ServiceTime, Phase2ServiceTime, Throughput,...
                ProcWaiting, ProcUtilization);
            
            CallIndices = find(self.model.lqnGraph.Edges.Type>0);
            EndNodes = self.model.lqnGraph.Edges.EndNodes(CallIndices,:);
            SourceIndices = findnode(self.model.lqnGraph,EndNodes(:,1));
            SourceNode = self.model.lqnGraph.Nodes.Node(SourceIndices);
            TargetIndices = findnode(self.model.lqnGraph,EndNodes(:,2));
            TargetNode = self.model.lqnGraph.Nodes.Node(TargetIndices);
            CallTypeMap = {'Synchronous';'Asynchronous'};
            CallType = CallTypeMap(self.model.lqnGraph.Edges.Type(CallIndices));
            Waiting = self.result.RawAvg.Edges.Waiting(CallIndices);
            CallAvgTable = Table(SourceNode, TargetNode, CallType, Waiting);
        end
        
        function [result, iterations] = parseXMLResults(self, filename)
            % [RESULT, ITERATIONS] = PARSEXMLRESULTS(FILENAME)
            
            import javax.xml.parsers.*;
            import org.w3c.dom.*;
            import java.io.*;
            
            lqnGraph = self.model.getGraph;
            numOfNodes = height(lqnGraph.Nodes);
            numOfEdges = height(lqnGraph.Edges);
            Avg.Nodes.Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase1Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase2Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase1ServiceTime = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase2ServiceTime = NaN*ones(numOfNodes,1);
            Avg.Nodes.Throughput = NaN*ones(numOfNodes,1);
            Avg.Nodes.ProcWaiting = NaN*ones(numOfNodes,1);
            Avg.Nodes.ProcUtilization = NaN*ones(numOfNodes,1);
            Avg.Edges.Waiting = NaN*ones(numOfEdges,1);
            verbose = self.options.verbose;
            
            if nargin == 1
                verbose = 0;
            end
            
            % init Java XML parser and load file
            dbFactory = DocumentBuilderFactory.newInstance();
            dBuilder = dbFactory.newDocumentBuilder();
            
            [fpath,fname,~] = fileparts(filename);
            resultFilename = [fpath,filesep,fname,'.lqxo'];
            if verbose > 0
                w = warning('query');
                %warning off;
                fprintf(1,'Parsing LQNS result file: %s\n',resultFilename);
                warning(w);
            end
            
            doc = dBuilder.parse(resultFilename);
            doc.getDocumentElement().normalize();
            
            %NodeList
            solverParams = doc.getElementsByTagName('solver-params');
            for i = 0:solverParams.getLength()-1
                solverParam = solverParams.item(i);
                result = solverParam.getElementsByTagName('result-general');
                iterations = str2double(result.item(0).getAttribute('iterations'));
            end
            
            procList = doc.getElementsByTagName('processor');
            for i = 0:procList.getLength()-1
                %Node - Processor
                procElement = procList.item(i);
                procName = char(procElement.getAttribute('name'));
                procPos = findstring(lqnGraph.Nodes.Node,procName);
                procResult = procElement.getElementsByTagName('result-processor');
                uRes = str2double(procResult.item(0).getAttribute('utilization'));
                Avg.Nodes.ProcUtilization(procPos) = uRes;
                
                taskList = procElement.getElementsByTagName('task');
                for j = 0:taskList.getLength()-1
                    %Node - Task
                    taskElement = taskList.item(j);
                    taskName = char(taskElement.getAttribute('name'));
                    taskPos = findstring(lqnGraph.Nodes.Node,taskName);
                    taskResult = taskElement.getElementsByTagName('result-task');
                    uRes = str2double(taskResult.item(0).getAttribute('utilization'));
                    p1uRes = str2double(taskResult.item(0).getAttribute('phase1-utilization'));
                    p2uRes = str2double(taskResult.item(0).getAttribute('phase2-utilization'));
                    tRes = str2double(taskResult.item(0).getAttribute('throughput'));
                    puRes = str2double(taskResult.item(0).getAttribute('proc-utilization'));
                    Avg.Nodes.Utilization(taskPos) = uRes;
                    Avg.Nodes.Phase1Utilization(taskPos) = p1uRes;
                    Avg.Nodes.Phase2Utilization(taskPos) = ifthenelse(isempty(p2uRes),NaN,p2uRes);
                    Avg.Nodes.Throughput(taskPos) = tRes;
                    Avg.Nodes.ProcUtilization(taskPos) = puRes;
                    
                    entryList = taskElement.getElementsByTagName('entry');
                    for k = 0:entryList.getLength()-1
                        %Node - Entry
                        entryElement = entryList.item(k);
                        entryName = char(entryElement.getAttribute('name'));
                        entryPos = findstring(lqnGraph.Nodes.Node,entryName);
                        entryResult = entryElement.getElementsByTagName('result-entry');
                        uRes = str2double(entryResult.item(0).getAttribute('utilization'));
                        p1uRes = str2double(entryResult.item(0).getAttribute('phase1-utilization'));
                        p2uRes = str2double(entryResult.item(0).getAttribute('phase2-utilization'));
                        p1stRes = str2double(entryResult.item(0).getAttribute('phase1-service-time'));
                        p2stRes = str2double(entryResult.item(0).getAttribute('phase2-service-time'));
                        tRes = str2double(entryResult.item(0).getAttribute('throughput'));
                        puRes = str2double(entryResult.item(0).getAttribute('proc-utilization'));
                        Avg.Nodes.Utilization(entryPos) = uRes;
                        Avg.Nodes.Phase1Utilization(entryPos) = p1uRes;
                        Avg.Nodes.Phase2Utilization(entryPos) = ifthenelse(isempty(p2uRes),NaN,p2uRes);
                        Avg.Nodes.Phase1ServiceTime(entryPos) = p1stRes;
                        Avg.Nodes.Phase2ServiceTime(entryPos) = ifthenelse(isempty(p2stRes),NaN,p2stRes);
                        Avg.Nodes.Throughput(entryPos) = tRes;
                        Avg.Nodes.ProcUtilization(entryPos) = puRes;
                    end
                    
                 %% task-activities
                    taskActivities = taskElement.getElementsByTagName('task-activities');
                    if taskActivities.getLength > 0
                        actList = taskActivities.item(0).getElementsByTagName('activity');
                        for l = 0:actList.getLength()-1
                            %Node - Activity
                            actElement = actList.item(l);
                            if strcmp(char(actElement.getParentNode().getNodeName()),'task-activities')
                                actName = char(actElement.getAttribute('name'));
                                actPos = findstring(lqnGraph.Nodes.Node,actName);
                                actResult = actElement.getElementsByTagName('result-activity');
                                uRes = str2double(actResult.item(0).getAttribute('utilization'));
                                stRes = str2double(actResult.item(0).getAttribute('service-time'));
                                tRes = str2double(actResult.item(0).getAttribute('throughput'));
                                pwRes = str2double(actResult.item(0).getAttribute('proc-waiting'));
                                puRes = str2double(actResult.item(0).getAttribute('proc-utilization'));
                                Avg.Nodes.Utilization(actPos) = uRes;
                                Avg.Nodes.Phase1ServiceTime(actPos) = stRes;
                                Avg.Nodes.Throughput(actPos) = tRes;
                                Avg.Nodes.ProcWaiting(actPos) = pwRes;
                                Avg.Nodes.ProcUtilization(actPos) = puRes;
                                
                                actID = lqnGraph.Nodes.Name{actPos};
                                synchCalls = actElement.getElementsByTagName('synch-call');
                                for m = 0:synchCalls.getLength()-1
                                    %Call - Synchronous
                                    callElement = synchCalls.item(m);
                                    destName = char(callElement.getAttribute('dest'));
                                    destPos = findstring(lqnGraph.Nodes.Node,destName);
                                    destID = lqnGraph.Nodes.Name{destPos};
                                    callPos = findedge(lqnGraph,actID,destID);
                                    callResult = callElement.getElementsByTagName('result-call');
                                    wRes = str2double(callResult.item(0).getAttribute('waiting'));
                                    Avg.Edges.Waiting(callPos) = wRes;
                                end
                                
                                asynchCalls = actElement.getElementsByTagName('asynch-call');
                                for m = 0:asynchCalls.getLength()-1
                                    %Call - Asynchronous
                                    callElement = asynchCalls.item(m);
                                    destName = char(callElement.getAttribute('dest'));
                                    destPos = findstring(lqnGraph.Nodes.Node,destName);
                                    destID = lqnGraph.Nodes.Name{destPos};
                                    callPos = findedge(lqnGraph,actID,destID);
                                    callResult = callElement.getElementsByTagName('result-call');
                                    wRes = str2double(callResult.item(0).getAttribute('waiting'));
                                    Avg.Edges.Waiting(callPos) = wRes;
                                end
                            end
                        end
                    end
                end
            end
            
            self.result.RawAvg = Avg;
            self.result.Avg.QLen = Avg.Nodes.Utilization(:);
            self.result.Avg.Util = Avg.Nodes.ProcUtilization(:);
            self.result.Avg.RespT = Avg.Nodes.Phase1ServiceTime(:);
            self.result.Avg.Tput = Avg.Nodes.Throughput(:);
            result = self.result;
        end
        
    end
    
    methods (Static)
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Coxian','Erlang','Exponential','HyperExp',...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_PS','SchedStrategy_FCFS','ClosedClass'});
            bool = true;
            for e=1:model.getNumberOfLayers()
                bool = bool && SolverFeatureSet.supports(featSupported, featUsed{e});
            end
        end
        
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('LQNS');
        end
        
        
        function bool = isAvailable()
            % BOOL = ISAVAILABLE()
            
            bool = true;
            if ispc % windows
                [~,ret] = dos('lqns -V -H');
                if containsstr(ret,'not recognized')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            else %linux
                [~,ret] = unix('lqns -V -H');
                if containsstr(ret,'command not found')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            end
            if ispc % windows
                [~,ret] = dos('lqsim -V -H');
                if containsstr(ret,'not recognized')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            else %linux
                [~,ret] = unix('lqsim -V -H');
                if containsstr(ret,'command not found')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            end
        end
    end
end
