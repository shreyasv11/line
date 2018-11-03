function myLN = parseXML(filename, verbose)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.


import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;

import LayeredNetwork.*;

% LQN
myLN = LayeredNetwork(filename);

if nargin == 1
    verbose = 0;
end

% init Java XML parser and load file
dbFactory = DocumentBuilderFactory.newInstance();
dBuilder = dbFactory.newDocumentBuilder();
try
    doc = dBuilder.parse(filename);
catch exception %java.io.FileNotFoundException
    if ~exist(filename, 'file')
        disp(['Error: Input XML file ', filename, ' not found']);
        processors = [];
        myLN.objects.processors = processors;
        
        return;
    else
        rethrow(exception);
    end
end

doc.getDocumentElement().normalize();
if verbose > 0
    disp(['Parsing LQN file: ', filename] );
    disp(['Root element :', char(doc.getDocumentElement().getNodeName()) ] );
end

%NodeList
procList = doc.getElementsByTagName('processor');

processors = [];
%providers = cell(0); % list of entries that provide services - Entry, Task, Proc
requesters = cell(0); % list of activities that request services - Act, Task, Proc
tasks = cell(0); %list of tasks - Task, task ID, Proc, ProcID - Row Index as task ID
entries = cell(0); %list of entries - Entry, Task ID
taskID = 1;
%demand is always indicated in an entry activity
procID = 1;
actObj = cell(0);
entryObj = cell(0);
taskObj = cell(0);
procObj = cell(0);

clients = []; % list of tasks that act as pure clients (think time)
for i = 0:procList.getLength()-1
    %Node - Processor
    procNode = procList.item(i);
    
    if procNode.getNodeType() == Node.ELEMENT_NODE
        
        %Element
        procElement = procNode;
        name = char(procElement.getAttribute('name'));
        multiplicity = str2num(char(procElement.getAttribute('multiplicity')));
        scheduling = char(procElement.getAttribute('scheduling'));
        switch scheduling
            case 'inf'
                if isempty(multiplicity)
                    multiplicity = Inf;
                    warning('Missing multiplicity for infinite-server processor, set to default value (Inf).')
                else
                    if ~isinf(multiplicity)
                        multiplicity = Inf;
                        warning('Multiplicity for infinite-server processor is incorrect, set to default value (Inf).')
                    end
                end
            otherwise
                if isempty(multiplicity)
                    multiplicity = 1;
                    warning('No multiplicity specified in processor, assuming default value (1.0).')
                end
        end
        quantum = str2double(char(procElement.getAttribute('quantum')));
        speedFactor = str2double(char(procElement.getAttribute('speed-factor')));
        tempProc = Processor(myLN, name, multiplicity, scheduling, quantum, speedFactor);
        procObj{end+1} = tempProc;
        
        taskList = procNode.getElementsByTagName('task');
        for j = 0:taskList.getLength()-1
            %Node - Task
            taskNode = taskList.item(j);
            if taskNode.getNodeType() == Node.ELEMENT_NODE
                %Element
                taskElement = taskNode;
                name = char(taskElement.getAttribute('name'));
                multiplicity = str2num(char(taskElement.getAttribute('multiplicity')));
                % map XML notation for scheduling into LINE scheduling strategy
                scheduling = char(taskElement.getAttribute('scheduling')); % this assumes that SchedStrategy uses the same property strings as the XML
                switch scheduling
                    case 'inf'
                        if isempty(multiplicity)
                            multiplicity = Inf;
                            warning('No multiplicity specified in infinite-server task, assuming default value (Inf).')
                        else
                            if ~isinf(multiplicity)
                                multiplicity = Inf;
                                warning('Incorrect multiplicity specified in infinite-server task, assuming default value (Inf).')
                            end
                        end
                    otherwise
                        if isempty(multiplicity)
                            multiplicity = 1;
                            warning('No multiplicity specified in task, assuming default value (1.0).')
                        end
                end
                thinkTime = str2double(char(taskElement.getAttribute('think-time')));
                % check if attribute is specified as thinkTime instead of
                % think-time, as in the LQXO format
                if isnan(thinkTime)
                    thinkTime = str2double(char(taskElement.getAttribute('thinkTime')));
                end
                actGraph = char(taskElement.getAttribute('activity-graph'));
                tempTask = Task(myLN, name, multiplicity, scheduling, thinkTime);
                taskObj{end+1} = tempTask;
                % determine reference task
                if strcmp(tempTask.scheduling, 'ref')
                    if thinkTime > 0
                        clients = [clients; taskID];
                    else
                        err = MException('ParseLQNXML:ZeroThinkTime', ...
                            ['The think time specified in ', tempProc.name, ' is zero.\nThink time must be a positive real']);
                        throw(err);
                        
                    end
                end
                
                entryList = taskNode.getElementsByTagName('entry');
                for k = 0:entryList.getLength()-1
                    %Node - Task
                    entryNode = entryList.item(k);
                    if entryNode.getNodeType() == Node.ELEMENT_NODE
                        %Element
                        entryElement = entryNode;
                        ename = char(entryElement.getAttribute('name'));
                        type = char(entryElement.getAttribute('type'));
                        tempEntry = Entry(myLN, ename, type);
                        entryObj{end+1} = tempEntry;
                        actList = entryNode.getElementsByTagName('activity');
                        for l = 0:actList.getLength()-1
                            %Node - Task
                            actNode = actList.item(l);
                            if actNode.getNodeType() == Node.ELEMENT_NODE
                                %Element
                                actElement = actNode;
                                name = char(actElement.getAttribute('name'));
                                phase = str2num(char(actElement.getAttribute('phase')));
                                demandMean = str2double(char(actElement.getAttribute('host-demand-mean')));
                                boundEntry = char(actElement.getAttribute('bound-to-entry'));
                                if isempty(boundEntry) && actList.getLength()==1 % if there is no bound to entry and there is a single activity, set it to be the one bound to entry
                                    boundEntry = tempEntry.name;
                                end
                                tempAct = Activity(myLN, name, demandMean, boundEntry, phase);
                                actObj{end+1} = tempAct;
                                %providers{size(providers,1)+1,1} = tempAct.name;
                                %providers{size(providers,1),2} = tempEntry.name;
                                %providers{size(providers,1),3} = tempTask.name;
                                %providers{size(providers,1),4} = tempProc.name;
                                %providers{size(providers,1),5} = procID;
                                
                                %providers:
                                % activity - entry - task - processor
                                
                                %actual processors
                                %if demandMean > 0 && isempty(find(cell2mat( {physical{:,2}}) == procID))
                                tempEntry = tempEntry.addActivity(tempAct);
                                actObj{end+1} = tempAct;
                            end
                        end
                        
                        entries{size(entries,1)+1,1} = tempEntry.name;
                        entries{size(entries,1),2} = taskID;
                        tempTask = tempTask.addEntry(tempEntry);
                    end
                end
                
                %% task-activities
                if taskElement.getElementsByTagName('task-activities').getLength > 0
                    actNames = cell(0); iterActNames = 1;
                    %actCalls = cell(0);
                    actList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('activity');
                    for l = 0:actList.getLength()-1
                        %Node - Task
                        actNode = actList.item(l);
                        if actNode.getNodeType() == Node.ELEMENT_NODE && strcmp(char(actNode.getParentNode().getNodeName()),'task-activities')
                            %Element
                            actElement = actNode;
                            name = char(actElement.getAttribute('name'));
                            phase = str2num(char(actElement.getAttribute('phase')));
                            demandMean = str2double(char(actElement.getAttribute('host-demand-mean')));
                            boundEntry = char(actElement.getAttribute('bound-to-entry'));
                            tempAct = Activity(myLN, name, demandMean, boundEntry, phase);
                            tempAct.setParent(tempTask.name);
                            actNames{iterActNames,1} = name;
                            if ~isempty(boundEntry)
                                tempTask = tempTask.setInitActivity(iterActNames);
                            end
                            
                            synchCalls = actElement.getElementsByTagName('synch-call');
                            asynchCalls = actElement.getElementsByTagName('asynch-call');
                            %add synch calls if any
                            if synchCalls.getLength() > 0
                                for m = 0:synchCalls.getLength()-1
                                    callElement = synchCalls.item(m);
                                    dest = char(callElement.getAttribute('dest'));
                                    mean = str2double(char(callElement.getAttribute('calls-mean')));
                                    tempAct = tempAct.synchCall(dest,mean);
                                    %actCalls{iterActNames,1} = dest;
                                    requesters{size(requesters,1)+1,1} = tempAct.name;
                                    requesters{size(requesters,1),2} = taskID;
                                    requesters{size(requesters,1),3} = tempProc.name;
                                    requesters{size(requesters,1),4} = dest;
                                    requesters{size(requesters,1),5} = procID;
                                    %requesters:
                                    % activity - task - processor - dest (entry) - procID
                                end
                                %else
                                %    actCalls{iterActNames,1} = [];
                                %end
                                %iterActNames = iterActNames + 1;
                                %add asynch calls if any
                            elseif asynchCalls.getLength() > 0
                                for m = 0:asynchCalls.getLength()-1
                                    callElement = asynchCalls.item(m);
                                    dest = char(callElement.getAttribute('dest'));
                                    mean = str2double(char(callElement.getAttribute('calls-mean')));
                                    tempAct = tempAct.asynchCall(dest,mean);
                                    %actCalls{iterActNames,1} = dest;
                                    requesters{size(requesters,1)+1,1} = tempAct.name;
                                    requesters{size(requesters,1),2} = taskID;
                                    requesters{size(requesters,1),3} = tempProc.name;
                                    requesters{size(requesters,1),4} = dest;
                                    requesters{size(requesters,1),5} = procID;
                                end
                            else
                                %actCalls{iterActNames,1} = [];
                            end
                            iterActNames = iterActNames + 1;
                            tempTask = tempTask.addActivity(tempAct);
                            actObj{end+1} = tempAct;
                        end
                    end
                    
                    %reply-entry
                    replyNames = cell(0); 
                    replyCalls = cell(0);
                    replyList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('reply-entry');
                    for l = 0:replyList.getLength()-1
                        %Node - Task
                        replyNode = replyList.item(l);
                        if replyNode.getNodeType() == Node.ELEMENT_NODE && strcmp(char(replyNode.getParentNode().getNodeName()),'task-activities')
                            %Element
                            replyElement = replyNode;
                            entryReplyName = char(replyElement.getAttribute('name'));
                            replyAct = replyElement.getElementsByTagName('reply-activity');
                            if replyAct.getLength() > 0
                                for m = 0:replyAct.getLength()-1
                                    callElement = replyAct.item(m);
                                    actReplyName = char(callElement.getAttribute('name'));
                                    eReplyIdx = find(cellfun(@(x) strcmp(x.name, entryReplyName), entryObj));
                                    entryObj{eReplyIdx}.replyActivity{end+1} = actReplyName;
                                end
                            end
                        end
                    end                    

                    %precedences
                    precList = taskElement.getElementsByTagName('task-activities').item(0).getElementsByTagName('precedence');
                    actGraph = zeros(length(actNames));
                    for l = 0:precList.getLength()-1
                        %Node - Precedence
                        precNode = precList.item(l);
                        if precNode.getNodeType() == Node.ELEMENT_NODE
                            %Element
                            precElement = precNode;
                            
                            
                            %pre
                            presList = precElement.getElementsByTagName('pre');
                            if presList.getLength > 0
                                pres = cell(1);
                                pres{1} = char(presList.item(0).getElementsByTagName('activity').item(0).getAttribute('name'));
                                preType = 'single';
                                
                                preIdxs = findstring(actNames,pres{1});
                            else
                                presList = precElement.getElementsByTagName('pre-OR').item(0).getElementsByTagName('activity');
                                pres = cell(presList.getLength,1);
                                preIdxs = zeros(presList.getLength,1);
                                for m = 1:presList.getLength
                                    pres{m} = char(presList.item(m-1).getAttribute('name'));
                                    preIdxs(m) = findstring(actNames,pres{m});
                                end
                                preType = 'OR';
                            end
                            
                            %post
                            postsList = precElement.getElementsByTagName('post');
                            if postsList.getLength > 0
                                posts = cell(1);
                                postProbs = [];
                                posts{1} = char(postsList.item(0).getElementsByTagName('activity').item(0).getAttribute('name'));
                                postType = 'single';
                                postIdxs = findstring(actNames,posts{1});
                            else
                                postsListOR = precElement.getElementsByTagName('post-OR');
                                if postsListOR.getLength >0
                                    postsList = postsListOR.item(0).getElementsByTagName('activity');
                                    posts = cell(postsList.getLength,1);
                                    postProbs = zeros(postsList.getLength,1);
                                    postIdxs = zeros(postsList.getLength,1);
                                    for m = 1:postsList.getLength
                                        posts{m} = char(postsList.item(m-1).getAttribute('name'));
                                        postProbs(m) = str2double( char(postsList.item(m-1).getAttribute('prob')) );
                                        postIdxs(m) = findstring(actNames,posts{m});
                                    end
                                    postType = 'OR';
                                end
                                postsListAND = precElement.getElementsByTagName('post-AND');
                                if postsListAND.getLength >0
                                    postsList = postsListAND.item(0).getElementsByTagName('activity');
                                    posts = cell(postsList.getLength,1);
                                    postProbs = zeros(postsList.getLength,1);
                                    postIdxs = zeros(postsList.getLength,1);
                                    for m = 1:postsList.getLength
                                        posts{m} = char(postsList.item(m-1).getAttribute('name'));
                                        postProbs(m) = str2double( char(postsList.item(m-1).getAttribute('prob')) );
                                        postIdxs(m) = findstring(actNames,posts{m});
                                    end
                                    postType = 'AND';
                                end
                            end
                            tempPrec = ActivityPrecedence(pres, posts, preType, postType, postProbs);
                            tempTask = tempTask.addPrecedence(tempPrec);
                             
%                             if length(postIdxs) == 1
%                                 for kIn = preIdxs
%                                     actGraph(kIn,postIdxs) = 1;
%                                 end
%                             else
%                                 for kOut = 1:length(postIdxs)
%                                     actGraph(preIdxs, postIdxs(kOut)) = postProbs(kOut);
%                                 end
%                             end
                        end
                    end
%                    tempTask = tempTask.setActGraph(actGraph,actNames);
                end
                
                tasks{size(tasks,1)+1,1} = tempTask.name;
                tasks{size(tasks,1),2} = taskID;
                tass{size(tasks,1),3} = tempProc.name;
                tasks{size(tasks,1),4} = procID;
                tempProc = tempProc.addTask(tempTask);
                taskID = taskID + 1;
                procID = procID + 1;
            end
        end
        
        processors = [processors; tempProc];
    end
end

myLN.processors = processors;
end