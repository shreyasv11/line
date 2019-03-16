classdef SolverLQNS < LayeredNetworkSolver
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    methods
        function self = SolverLQNS(model, varargin)
            self = self@LayeredNetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if ~SolverLQNS.isAvailable()
                error('SolverLQNS requires the lqns and lqsim commands to be available on the system path. Quitting.');
            end
        end        
        
        function runtime = run(self)
            tic;
            options = self.getOptions;
            filename = [tempname,'.lqnx'];
            self.model.writeXML(filename);
            switch options.method
                case {'default','lqns'}
                    system(['lqns -i',num2str(options.iter_max),' -x ',filename]);
                case 'exact'
                    system(['lqns -Playering=srvn -i',num2str(options.iter_max),' -Pmva=exact -x ',filename]);
                case {'srvn'}
                    system(['lqns -Playering=srvn -i',num2str(options.iter_max),' -x ',filename]);
                case 'srvnexact'
                    system(['lqns -Playering=srvn -i',num2str(options.iter_max),' -Pmva=exact -x ',filename]);
                case {'sim','lqsim'}
                    system(['lqsim -A ',num2str(options.samples),',0.95 -x ',filename]);
                case {'lqnsdefault'}
                    system(['lqns -x ',filename]);
                otherwise
                    system(['lqns -Playering=srvn -i',num2str(options.iter_max),' -x ',filename]);
            end
            self.parseXMLResults(filename);
            if ~options.keep
                delete(filename)
            end
            runtime = toc;
        end
        
        function reset(self)
            model.reset;
        end
        
        function [QN,UN,RN,TN] = getAvg(self,~,~,~,~)
            self.run();
            QN = self.result.Avg.QLen;
            UN = self.result.Avg.Util;
            RN = self.result.Avg.RespT;
            TN = self.result.Avg.Tput;
        end
        
        function [result, iterations] = parseXMLResults(self, filename)
            import javax.xml.parsers.*;
            import org.w3c.dom.*;
            import java.io.*;
            
            model = self.model;
            Avg = struct();
            Avg.Nodes.RespT = [];
            Avg.Nodes.Tput = [];
            Avg.Nodes.Util = [];
            Avg.Nodes.QLen = [];
            Avg.Edges.RespT = [];
            Avg.Edges.Tput = [];
            Avg.Edges.QLen = [];
            lqnGraph = model.getGraph;
            verbose = self.options.verbose;
            
            if nargin == 1
                verbose = 0;
            end
            
            % init Java XML parser and load file
            dbFactory = DocumentBuilderFactory.newInstance();
            dBuilder = dbFactory.newDocumentBuilder();
            try
                [fpath,fname,fext] = fileparts(filename);
                resultFilename = [fpath,filesep,fname,'.lqxo'];
                if verbose > 0
                    w = warning('query');
                    warning off;
                    fprintf(1,'Parsing LQNS result file: %s\n', resultFilename);
                    warning(w);
                end
                doc = dBuilder.parse(resultFilename);
            catch exception %java.io.FileNotFoundException
                if ~exist(filename, 'file')
                    disp(['Error: Input XML file ', filename, ' not found']);
                    return;
                else
                    rethrow(exception);
                end
            end
            
            doc.getDocumentElement().normalize();
            
            %NodeList
            solverPara = doc.getElementsByTagName('solver-params');
            for i = 0:solverPara.getLength()-1
                procNode = solverPara.item(i);
                result = procNode.getElementsByTagName('result-general');
                iterations = str2num(result.item(0).getAttribute('iterations'));
            end
            
            procList = doc.getElementsByTagName('processor');
            for i = 0:procList.getLength()-1
                %Node - Processor
                procNode = procList.item(i);
                
                if procNode.getNodeType() == Node.ELEMENT_NODE
                    
                    %Element
                    procElement = procNode;
                    name = char(procElement.getAttribute('name'));
                    procPos = findstring(lqnGraph.Nodes.Node,name);
                    result = procNode.getElementsByTagName('result-processor');
                    utilizationRes = str2num(result.item(0).getAttribute('utilization'));
                    Avg.Nodes.Util(procPos) = utilizationRes;
                    Avg.Nodes.QLen(procPos) = NaN;
                    Avg.Nodes.RespT(procPos) = NaN;
                    Avg.Nodes.Tput(procPos) = NaN;
                    
                    taskList = procNode.getElementsByTagName('task');
                    for j = 0:taskList.getLength()-1
                        %Node - Task
                        taskNode = taskList.item(j);
                        if taskNode.getNodeType() == Node.ELEMENT_NODE
                            taskElement = taskNode;
                            name = char(taskElement.getAttribute('name'));
                            result = taskNode.getElementsByTagName('result-task');
                            Avg.Nodes.Util(findstring(lqnGraph.Nodes.Node,name)) = str2num(result.item(0).getAttribute('proc-utilization'));
                            Avg.Nodes.QLen(findstring(lqnGraph.Nodes.Node,name)) = str2num(result.item(0).getAttribute('utilization'));
                            Avg.Nodes.RespT(findstring(lqnGraph.Nodes.Node,name)) = NaN;
                            Avg.Nodes.Tput(findstring(lqnGraph.Nodes.Node,name)) = str2num(result.item(0).getAttribute('throughput'));
                            entryList = taskNode.getElementsByTagName('entry');
                            for k = 0:entryList.getLength()-1
                                %Node - Task
                                entryNode = entryList.item(k);
                                if entryNode.getNodeType() == Node.ELEMENT_NODE
                                    %Element
                                    entryElement = entryNode;
                                    name = char(entryElement.getAttribute('name'));
                                    result = entryNode.getElementsByTagName('result-entry');
                                    utilizationRes = str2num(result.item(0).getAttribute('proc-utilization'));
                                    Avg.Nodes.Util(findstring(lqnGraph.Nodes.Node,name)) = utilizationRes;
                                    qlenRes = str2num(result.item(0).getAttribute('utilization'));
                                    Avg.Nodes.QLen(findstring(lqnGraph.Nodes.Node,name)) = qlenRes;
                                    tputRes = str2num(result.item(0).getAttribute('throughput'));
                                    Avg.Nodes.Tput(findstring(lqnGraph.Nodes.Node,name)) = tputRes;
                                    rtRes = str2num(result.item(0).getAttribute('phase1-service-time'));
                                    if ~isempty(rtRes)
                                        Avg.Nodes.RespT(findstring(lqnGraph.Nodes.Node,name)) = rtRes;
                                    end
                                end
                            end
                            
                            %% task-activities
                            if taskElement.getElementsByTagName('task-activities').getLength > 0
                                %actNames = cell(0); iterActNames = 1;
                                %actCalls = cell(0);
                                actList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('activity');
                                for l = 0:actList.getLength()-1
                                    %Node - Task
                                    actNode = actList.item(l);
                                    if actNode.getNodeType() == Node.ELEMENT_NODE && strcmp(char(actNode.getParentNode().getNodeName()),'task-activities')
                                        %Element
                                        actElement = actNode;
                                        name = char(actElement.getAttribute('name'));
                                        
                                        result = actNode.getElementsByTagName('result-activity');
                                        rtRes = str2num(result.item(0).getAttribute('service-time'));
                                        Avg.Nodes.RespT(findstring(lqnGraph.Nodes.Node,name)) = rtRes;
                                        utilizationRes = str2num(result.item(0).getAttribute('proc-utilization'));
                                        Avg.Nodes.Util(findstring(lqnGraph.Nodes.Node,name)) = utilizationRes;
                                        qlenRes = str2num(result.item(0).getAttribute('utilization'));
                                        Avg.Nodes.QLen(findstring(lqnGraph.Nodes.Node,name)) = qlenRes;
                                        tputRes = str2num(result.item(0).getAttribute('throughput'));
                                        Avg.Nodes.Tput(findstring(lqnGraph.Nodes.Node,name)) = tputRes;
                                        
                                        %                             synchCalls = actElement.getElementsByTagName('synch-call');
                                        %                             asynchCalls = actElement.getElementsByTagName('asynch-call');
                                        %                             %add synch calls if any
                                        %                             if synchCalls.getLength() > 0
                                        %                                 for m = 0:synchCalls.getLength()-1
                                        %                                     callElement = synchCalls.item(m);
                                        %                                     dest = char(callElement.getAttribute('dest'));
                                        %                                     mean = str2double(char(callElement.getAttribute('calls-mean')));
                                        %                                     tempAct = tempAct.synchCall(dest,mean);
                                        %                                     actCalls{iterActNames,1} = dest;
                                        %                                     requesters{size(requesters,1)+1,1} = tempAct.name;
                                        %                                     requesters{size(requesters,1),2} = taskID;
                                        %                                     requesters{size(requesters,1),3} = tempProc.name;
                                        %                                     requesters{size(requesters,1),4} = dest;
                                        %                                     requesters{size(requesters,1),5} = procID;
                                        %                                     %requesters:
                                        %                                     % activity - task - processor - dest (entry) - procID
                                        %                                 end
                                        %                                 %else
                                        %                                 %    actCalls{iterActNames,1} = [];
                                        %                                 %end
                                        %                                 %iterActNames = iterActNames + 1;
                                        %                                 %add asynch calls if any
                                        %                             elseif asynchCalls.getLength() > 0
                                        %                                 for m = 0:asynchCalls.getLength()-1
                                        %                                     callElement = asynchCalls.item(m);
                                        %                                     dest = char(callElement.getAttribute('dest'));
                                        %                                     mean = str2double(char(callElement.getAttribute('calls-mean')));
                                        %                                     tempAct = tempAct.asynchCall(dest,mean);
                                        %                                     actCalls{iterActNames,1} = dest;
                                        %                                     requesters{size(requesters,1)+1,1} = tempAct.name;
                                        %                                     requesters{size(requesters,1),2} = taskID;
                                        %                                     requesters{size(requesters,1),3} = tempProc.name;
                                        %                                     requesters{size(requesters,1),4} = dest;
                                        %                                     requesters{size(requesters,1),5} = procID;
                                        %                                 end
                                        %                             else
                                        %                                 actCalls{iterActNames,1} = [];
                                        %                             end
                                        %iterActNames = iterActNames + 1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            %             for edge=1:height(lqnGraph.Edges)
            %                 if lqnGraph.Edges.Type(edge) == 1 % add contribution of sync-calls
            %                     syncSource = lqnGraph.Edges.EndNodes{edge,1};
            %                     aidx = findstring(lqnGraph.Nodes.Name,syncSource);
            %                     if lqnGraph.Edges.Weight(edge) >= 1
            %                         Avg.Nodes.RespT(aidx) = Avg.Nodes.RespT(aidx) +  Avg.Edges.RespT(edge) * lqnGraph.Edges.Weight(edge);
            %                     else
            %                         Avg.Nodes.RespT(aidx) = Avg.Nodes.RespT(aidx) +  Avg.Edges.RespT(edge);
            %                     end
            %                 end
            %             end
            
            self.result = struct();
            self.result.Avg = struct();
            self.result.Avg.Graph = lqnGraph;
            self.result.Avg.QLen = Avg.Nodes.QLen(:);
            self.result.Avg.Util = Avg.Nodes.Util(:);
            self.result.Avg.RespT = Avg.Nodes.RespT(:);
            self.result.Avg.Tput = Avg.Nodes.Tput(:);
            result = self.result;
        end
        
    end
    
    methods (Static)
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_PS','SchedStrategy_FCFS','ClosedClass'});
            bool = true;
            for e=1:model.getNumberOfLayers()
                bool = bool && SolverFeatureSet.supports(featSupported, featUsed{e});
            end
        end
        
        function options = defaultOptions(self)
            options = EnsembleSolver.defaultOptions();
            options.timespan = [Inf,Inf];
            options.keep = false;
        end
        
        function bool = isAvailable()
            bool = true;
            if ispc % windows
                [~,ret] = dos('lqns -h'); 
                if contains(ret,'not recognized')
                    bool = false;
                end
            else %linux
                [~,ret] = unix('lqns -h'); 
                if contains(ret,'command not found')                             
                    bool = false;
                end
            end
            if ispc % windows
                [~,ret] = dos('lqsim -h'); 
                if contains(ret,'not recognized')
                    bool = false;
                end
            else %linux
                [~,ret] = unix('lqsim -h'); 
                if contains(ret,'command not found')                             
                    bool = false;
                end
            end
        end
    end
end
