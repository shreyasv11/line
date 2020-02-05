function myLN = parseXML(filename, verbose)
% MYLN = PARSEXML(FILENAME, VERBOSE)

% Copyright (c) 2012-2020, Imperial College London
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

if ~exist('verbose','var')
    verbose = 0;
end

% init Java XML parser and load file
dbFactory = DocumentBuilderFactory.newInstance();
dBuilder = dbFactory.newDocumentBuilder();

doc = dBuilder.parse(filename);
doc.getDocumentElement().normalize();
if verbose > 0
    disp(['Parsing LQN file: ',filename]);
    disp(['Root element :',char(doc.getDocumentElement().getNodeName())]);
end

processors = cell(0); %list of processors - Proc
tasks = cell(0); %list of tasks - Task, ProcID
entries = cell(0); %list of entries - Entry, TaskID, ProcID
activities = cell(0); %list of activities - Act, TaskID, ProcID
procID = 1;
taskID = 1;
entryID = 1;
actID = 1;
procObj = cell(0);
taskObj = cell(0);
entryObj = cell(0);
actObj = cell(0);

procList = doc.getElementsByTagName('processor');
for i = 0:procList.getLength()-1
    %Element - Processor
    procElement = procList.item(i);
    name = char(procElement.getAttribute('name'));
    scheduling = char(procElement.getAttribute('scheduling'));
    multiplicity = str2double(char(procElement.getAttribute('multiplicity')));
    if isnan(multiplicity)
        multiplicity = 1;
    end
    quantum = str2double(char(procElement.getAttribute('quantum')));
    if isnan(quantum)
        quantum = 0.001;
    end
    speedFactor = str2double(char(procElement.getAttribute('speed-factor')));
    if isnan(speedFactor)
        speedFactor = 1.0;
    end
    tempProc = Processor(myLN, name, multiplicity, scheduling, quantum, speedFactor);
    procObj{end+1,1} = tempProc;
    
    taskList = procElement.getElementsByTagName('task');
    for j = 0:taskList.getLength()-1
        %Element - Task
        taskElement = taskList.item(j);
        name = char(taskElement.getAttribute('name'));
        scheduling = char(taskElement.getAttribute('scheduling'));
        multiplicity = str2double(char(taskElement.getAttribute('multiplicity')));
        if isnan(multiplicity)
            multiplicity = 1;
        end
        thinkTimeMean = str2double(char(taskElement.getAttribute('think-time')));
        if isnan(thinkTimeMean)
            thinkTimeMean = 0.0;
        end
        if thinkTimeMean <= 0.0
            thinkTime = Immediate();
        else
            thinkTime = Exp.fitMean(thinkTimeMean);
        end
        tempTask = Task(myLN, name, multiplicity, scheduling, thinkTime);
        taskObj{end+1,1} = tempTask;
        
        entryList = taskElement.getElementsByTagName('entry');
        for k = 0:entryList.getLength()-1
            %Element - Entry
            entryElement = entryList.item(k);
            name = char(entryElement.getAttribute('name'));
            tempEntry = Entry(myLN, name);
            entryObj{end+1,1} = tempEntry;
            
            %entry-phase-activities
            entryPhaseActsList = entryElement.getElementsByTagName('entry-phase-activities');
            if entryPhaseActsList.getLength > 0
                entryPhaseActsElement = entryPhaseActsList.item(0);
                actList = entryPhaseActsElement.getElementsByTagName('activity');
                name = cell(actList.getLength(),1);
                for l = 0:actList.getLength()-1
                    %Element - Activity
                    actElement = actList.item(l);
                    phase = str2double(char(actElement.getAttribute('phase')));
                    name{phase} = char(actElement.getAttribute('name'));
                    hostDemandMean = str2double(char(actElement.getAttribute('host-demand-mean')));
                    hostDemandSCV = str2double(char(actElement.getAttribute('host-demand-cvsq')));
                    if isnan(hostDemandSCV)
                        hostDemandSCV = 1.0;
                    end
                    if hostDemandMean <= 0.0
                        hostDemand = Immediate();
                    else
                        if hostDemandSCV <= 0.0
                            hostDemand = Det(hostDemandMean);
                        elseif hostDemandSCV < 1.0
                            hostDemand = Gamma.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        elseif hostDemandSCV == 1.0
                            hostDemand = Exp.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        else
                            hostDemand = HyperExp.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        end
                    end
                    if phase == 1
                        boundToEntry = tempEntry.name;
                    else
                        boundToEntry = '';
                    end
                    callOrder = char(actElement.getAttribute('call-order'));
                    tempAct = Activity(myLN, name{phase}, hostDemand, boundToEntry, callOrder);
                    actObj{end+1,1} = tempAct;
                    
                    %synch-call
                    synchCalls = actElement.getElementsByTagName('synch-call');
                    for m = 0:synchCalls.getLength()-1
                        callElement = synchCalls.item(m);
                        dest = char(callElement.getAttribute('dest'));
                        mean = str2double(char(callElement.getAttribute('calls-mean')));
                        tempAct = tempAct.synchCall(dest,mean);
                    end
                    
                    %asynch-call
                    asynchCalls = actElement.getElementsByTagName('asynch-call');
                    for m = 0:asynchCalls.getLength()-1
                        callElement = asynchCalls.item(m);
                        dest = char(callElement.getAttribute('dest'));
                        mean = str2double(char(callElement.getAttribute('calls-mean')));
                        tempAct = tempAct.asynchCall(dest,mean);
                    end
                    
                    activities{end+1,1} = tempAct.name;
                    activities{end,2} = taskID;
                    activities{end,3} = procID;
                    tempTask = tempTask.addActivity(tempAct);
                    tempAct.parent = tempTask;
                    actID = actID+1;
                end
                
                %precedence
                for l = 1:length(name)-1
                    tempPrec = ActivityPrecedence(name(l), name(l+1));
                    tempTask = tempTask.addPrecedence(tempPrec);
                end
                
                %reply-entry
                if ~isempty(name)
                    tempEntry.replyActivity{1} = name{1};
                end
            end
            
            entries{end+1,1} = tempEntry.name;
            entries{end,2} = taskID;
            entries{end,3} = procID;
            tempTask = tempTask.addEntry(tempEntry);
            tempEntry.parent = tempTask;
            entryID = entryID+1;
        end
        
        %task-activities
        taskActsList = taskElement.getElementsByTagName('task-activities');
        if taskActsList.getLength > 0
            taskActsElement = taskActsList.item(0);
            actList = taskActsElement.getElementsByTagName('activity');
            for l = 0:actList.getLength()-1
                %Element - Activity
                actElement = actList.item(l);
                if strcmp(char(actElement.getParentNode().getNodeName()),'task-activities')
                    name = char(actElement.getAttribute('name'));
                    hostDemandMean = str2double(char(actElement.getAttribute('host-demand-mean')));
                    hostDemandSCV = str2double(char(actElement.getAttribute('host-demand-cvsq')));
                    if isnan(hostDemandSCV)
                        hostDemandSCV = 1.0;
                    end
                    if hostDemandMean <= 0.0
                        hostDemand = Immediate();
                    else
                        if hostDemandSCV <= 0.0
                            hostDemand = Det(hostDemandMean);
                        elseif hostDemandSCV < 1.0
                            hostDemand = Gamma.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        elseif hostDemandSCV == 1.0
                            hostDemand = Exp.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        else
                            hostDemand = HyperExp.fitMeanAndSCV(hostDemandMean, hostDemandSCV);
                        end
                    end
                    boundToEntry = char(actElement.getAttribute('bound-to-entry'));
                    callOrder = char(actElement.getAttribute('call-order'));
                    tempAct = Activity(myLN, name, hostDemand, boundToEntry, callOrder);
                    actObj{end+1,1} = tempAct;
                    
                    %synch-call
                    synchCalls = actElement.getElementsByTagName('synch-call');
                    for m = 0:synchCalls.getLength()-1
                        callElement = synchCalls.item(m);
                        dest = char(callElement.getAttribute('dest'));
                        mean = str2double(char(callElement.getAttribute('calls-mean')));
                        tempAct = tempAct.synchCall(dest,mean);
                    end
                    
                    %asynch-call
                    asynchCalls = actElement.getElementsByTagName('asynch-call');
                    for m = 0:asynchCalls.getLength()-1
                        callElement = asynchCalls.item(m);
                        dest = char(callElement.getAttribute('dest'));
                        mean = str2double(char(callElement.getAttribute('calls-mean')));
                        tempAct = tempAct.asynchCall(dest,mean);
                    end
                    
                    activities{end+1,1} = tempAct.name;
                    activities{end,2} = taskID;
                    activities{end,3} = procID;
                    tempTask = tempTask.addActivity(tempAct);
                    tempAct.parent = tempTask;
                    actID = actID+1;
                end
            end
            
            %precedence
            precList = taskActsElement.getElementsByTagName('precedence');
            for l = 0:precList.getLength()-1
                precElement = precList.item(l);
                
                %pre
                preTypes = {ActivityPrecedence.PRE_SEQ,ActivityPrecedence.PRE_AND,ActivityPrecedence.PRE_OR};
                for m = 1:length(preTypes)
                    preType = preTypes{m};
                    preList = precElement.getElementsByTagName(preType);
                    if preList.getLength() > 0
                        break
                    end
                end
                preElement = preList.item(0);
                preParams = str2double(char(preElement.getAttribute('quorum')));
                if isnan(preParams)
                    preParams = [];
                end
                preActList = preElement.getElementsByTagName('activity');
                preActs = cell(preActList.getLength(),1);
                for m = 0:preActList.getLength()-1
                    preActElement = preActList.item(m);
                    preActs{m+1} = char(preActElement.getAttribute('name'));
                end
                
                %post
                postTypes = {ActivityPrecedence.POST_SEQ,ActivityPrecedence.POST_AND,ActivityPrecedence.POST_OR,ActivityPrecedence.POST_LOOP};
                for m = 1:length(postTypes)
                    postType = postTypes{m};
                    postList = precElement.getElementsByTagName(postType);
                    if postList.getLength() > 0
                        break
                    end
                end
                postElement = postList.item(0);
                postActList = postElement.getElementsByTagName('activity');
                if strcmp(postType,ActivityPrecedence.POST_OR)
                    postActs = cell(postActList.getLength(),1);
                    postParams = zeros(postActList.getLength(),1);
                    for m = 0:postActList.getLength()-1
                        postActElement = postActList.item(m);
                        postActs{m+1} = char(postActElement.getAttribute('name'));
                        postParams(m+1) = str2double(char(postActElement.getAttribute('prob')));
                    end
                elseif strcmp(postType,ActivityPrecedence.POST_LOOP)
                    postActs = cell(postActList.getLength()+1,1);
                    postParams = zeros(postActList.getLength(),1);
                    for m = 0:postActList.getLength()-1
                        postActElement = postActList.item(m);
                        postActs{m+1} = char(postActElement.getAttribute('name'));
                        postParams(m+1) = str2double(char(postActElement.getAttribute('count')));
                    end
                    postActs{end} = char(postElement.getAttribute('end'));
                else
                    postActs = cell(postActList.getLength(),1);
                    postParams = [];
                    for m = 0:postActList.getLength()-1
                        postActElement = postActList.item(m);
                        postActs{m+1} = char(postActElement.getAttribute('name'));
                    end
                end
                
                tempPrec = ActivityPrecedence(preActs, postActs, preType, postType, preParams, postParams);
                tempTask = tempTask.addPrecedence(tempPrec);
            end
            
            %reply-entry
            replyList = taskActsElement.getElementsByTagName('reply-entry');
            for l = 0:replyList.getLength()-1
                replyElement = replyList.item(l);
                replyName = char(replyElement.getAttribute('name'));
                replyIdx = findstring(entries(:,1), replyName);
                replyActList = replyElement.getElementsByTagName('reply-activity');
                for m = 0:replyActList.getLength()-1
                    replyActElement = replyActList.item(m);
                    replyActName = char(replyActElement.getAttribute('name'));
                    entryObj{replyIdx}.replyActivity{end+1} = replyActName;
                end
            end
        end
        
        tasks{end+1,1} = tempTask.name;
        tasks{end,2} = procID;
        tempProc = tempProc.addTask(tempTask);
        taskID = taskID+1;
    end
    
    processors{end+1,1} = tempProc.name;
    procID = procID+1;
end
end
