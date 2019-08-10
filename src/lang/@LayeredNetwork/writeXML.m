function writeXML(self,filename)
% WRITEXML(SELF,FILENAME)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.OutputKeys;

precision = '%10.15e'; %precision for doubles
docFactory = DocumentBuilderFactory.newInstance();
docBuilder = docFactory.newDocumentBuilder();
doc = docBuilder.newDocument();

%Root Element
rootElement = doc.createElement('lqn-model');
doc.appendChild(rootElement);
rootElement.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
rootElement.setAttribute('xsi:noNamespaceSchemaLocation', 'lqn.xsd');
rootElement.setAttribute('name', self.getName());

for p = 1:length(self.processors)
    %processor
    curProc = self.processors(p);
    procElement = doc.createElement('processor');
    rootElement.appendChild(procElement);
    procElement.setAttribute('name', curProc.name);
    if isfinite(curProc.multiplicity)
        procElement.setAttribute('multiplicity', num2str(curProc.multiplicity));
    end
    procElement.setAttribute('scheduling', num2str(curProc.scheduling));
    if ~isnan(curProc.quantum)
        procElement.setAttribute('quantum', num2str(curProc.quantum));
    end
    if ~isnan(curProc.speedFactor)
        procElement.setAttribute('speed-factor', num2str(curProc.speedFactor));
    end
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        taskElement = doc.createElement('task');
        procElement.appendChild(taskElement);
        taskElement.setAttribute('name', curTask.name);
        taskElement.setAttribute('scheduling', curTask.scheduling);
        if isfinite(curTask.multiplicity)
            taskElement.setAttribute('multiplicity', num2str(curTask.multiplicity));
        end
        if ~isnan(curTask.thinkTimeMean)
            taskElement.setAttribute('think-time', num2str(curTask.thinkTimeMean));
        end
        for e=1:length(curTask.entries)
            curEntry = self.processors(p).tasks(t).entries(e);
            entryElement = doc.createElement('entry');
            taskElement.appendChild(entryElement);
            entryElement.setAttribute('name', curEntry.name);
            entryElement.setAttribute('type', curEntry.type);
            if ~isnan(curEntry.extArrivalMean)
                entryElement.setAttribute('open-arrival-rate', num2str(1/curEntry.extArrivalMean));
                taskElement.setAttribute('scheduling', SchedStrategy.INF);
            end
        end
        taskActElement = doc.createElement('task-activities');
        taskElement.appendChild(taskActElement);
        for a=1:length(curTask.activities)
            curAct = self.processors(p).tasks(t).activities(a);
            actElement = doc.createElement('activity');
            taskActElement.appendChild(actElement);
            actElement.setAttribute('host-demand-mean', num2str(curAct.hostDemandMean));
            actElement.setAttribute('host-demand-cvsq', num2str(curAct.hostDemandSCV));
            if ~isempty(curAct.boundToEntry)
                actElement.setAttribute('bound-to-entry', curAct.boundToEntry);
            end
            if ~isempty(curAct.callOrder)
                actElement.setAttribute('call-order', curAct.callOrder);
            end
            actElement.setAttribute('name', curAct.name);
            for sd=1:length(curAct.synchCallDests)
                syncCallElement = doc.createElement('synch-call');
                actElement.appendChild(syncCallElement);
                syncCallElement.setAttribute('dest',curAct.synchCallDests(sd));
                syncCallElement.setAttribute('calls-mean',num2str(curAct.synchCallMeans(sd)));
            end
            for asd=1:length(curAct.asynchCallDests)
                asyncCallElement = doc.createElement('asynch-call');
                actElement.appendChild(asyncCallElement);
                asyncCallElement.setAttribute('dest',curAct.asynchCallDests(asd));
                asyncCallElement.setAttribute('calls-mean',num2str(curAct.asynchCallMeans(asd)));
            end
        end
        for ap=1:length(curTask.precedences)
            actPrecedence = doc.createElement('precedence');
            taskActElement.appendChild(actPrecedence);
            curActPrec = self.processors(p).tasks(t).precedences(ap);
            
            precPreElement = doc.createElement('pre');
            actPrecedence.appendChild(precPreElement);
            precAct = doc.createElement('activity');
            precAct.setAttribute('name',curActPrec.pres{1});
            precPreElement.appendChild(precAct);
            
            precPostElement = doc.createElement('post');
            actPrecedence.appendChild(precPostElement);
            precAct = doc.createElement('activity');
            precAct.setAttribute('name',curActPrec.posts{1});
            precPostElement.appendChild(precAct);
        end
        for e=1:length(curTask.entries)
            curEntry = self.processors(p).tasks(t).entries(e);
            if ~isempty(curEntry.replyActivity)
                entryReplyElement = doc.createElement('reply-entry');
                taskActElement.appendChild(entryReplyElement);
                entryReplyElement.setAttribute('name', curEntry.name);
                for r=1:length(curEntry.replyActivity)
                    entryReplyActElement = doc.createElement('reply-activity');
                    entryReplyElement.appendChild(entryReplyActElement);
                    entryReplyActElement.setAttribute('name', curEntry.replyActivity{r});
                end
            end
        end
    end
end

%write the content into xml file
transformerFactory = TransformerFactory.newInstance();
transformer = transformerFactory.newTransformer();
transformer.setOutputProperty(OutputKeys.INDENT, 'yes');
source = DOMSource(doc);
result =  StreamResult(File(filename));
transformer.transform(source, result);
end
