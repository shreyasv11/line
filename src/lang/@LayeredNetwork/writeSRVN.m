function writeSRVN(self, filename)
% WRITESRVN(FILENAME)
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
fid = fopen(filename,'w+');
%fid = 1;
fprintf(fid,'G\n');
fprintf(fid,['"',self.name,'"\n']);
fprintf(fid,[num2str(Solver.defaultOptions.iter_tol),'\n']);
fprintf(fid,[num2str(Solver.defaultOptions.iter_max),'\n']);
fprintf(fid,['-1\n\n']);

%%
fprintf(fid,'#Processor block\n');
fprintf(fid,['P ',num2str(length(self.processors)),'\n']);
for p = 1:length(self.processors)
    curProc = self.processors(p);
    switch curProc.scheduling
        case SchedStrategy.FCFS
            fprintf(fid,['p ',curProc.name,' f m ',num2str(curProc.multiplicity),'\n']);
        case SchedStrategy.HOL
            fprintf(fid,['p ',curProc.name,' h m ',num2str(curProc.multiplicity),'\n']);
        case SchedStrategy.INF
            fprintf(fid,['p ',curProc.name,' i','\n']);
        case SchedStrategy.PS
            fprintf(fid,['p ',curProc.name,' s ',num2str(curProc.quantum),' m ',num2str(curProc.multiplicity),'\n']);
        case SchedStrategy.RAND
            fprintf(fid,['p ',curProc.name,' r m ',num2str(curProc.multiplicity),'\n']);
        otherwise
            error('Unsupported scheduling policy.');
    end
end

%%
fprintf(fid,'-1\n\n#Task block\n');
numTasks = 0;
for p = 1:length(self.processors)
    curProc = self.processors(p);
    numTasks = numTasks + length(curProc.tasks);
end
fprintf(fid,['T ',num2str(numTasks),'\n']);
for p = 1:length(self.processors)
    curProc = self.processors(p);
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        entryList = '';
        for e=1:length(curTask.entries)
            curEntry = self.processors(p).tasks(t).entries(e);
            entryList = [entryList,' ',curEntry.name];
        end
        entryList=entryList(2:end);
        switch curTask.scheduling
            case SchedStrategy.REF
                fprintf(fid,['t ',curTask.name,' r ',entryList,' -1 ',curProc.name,' z ',num2str(curTask.thinkTimeMean),' m ',num2str(curTask.multiplicity),'\n']);
            case SchedStrategy.FCFS
                fprintf(fid,['t ',curTask.name,' f ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            case SchedStrategy.HOL
                fprintf(fid,['t ',curTask.name,' h ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            case SchedStrategy.INF
                fprintf(fid,['t ',curTask.name,' i ',entryList,' -1 ',curProc.name,'\n']);
            case {SchedStrategy.PS, SchedStrategy.RAND, SchedStrategy.GPS, SchedStrategy.DPS}
                fprintf(fid,['t ',curTask.name,' n ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            otherwise
                error('Unsupported scheduling policy.');
        end
    end
end

%%
fprintf(fid,'-1\n\n#Entry block\n');

numEntry = 0;
for p = 1:length(self.processors)
    curProc = self.processors(p);
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        numEntry = numEntry + length(curTask.entries);
    end
end

fprintf(fid,['E ',num2str(numEntry),'\n']);
for p = 1:length(self.processors)
    curProc = self.processors(p);
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        for e=1:length(curTask.entries)
            curEntry = self.processors(p).tasks(t).entries(e);
            for a=1:length(curTask.activities)
                curAct = self.processors(p).tasks(t).activities(a);
                if strcmp(curAct.boundToEntry,curEntry.name)
                    fprintf(fid,['A ',curEntry.name,' ',curAct.name,'\n']);
                    break
                end
            end
        end
    end
end

%%
fprintf(fid,'-1\n\n#Activity blocks\n');
lqnGraph = self.getGraph;
for p = 1:length(self.processors)
    curProc = self.processors(p);
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        fprintf(fid,['A ',curTask.name,'\n']);
        % task activities
        for a=1:length(curTask.activities)
            curAct = self.processors(p).tasks(t).activities(a);
            fprintf(fid,['s ',curAct.name,' ',num2str(curAct.hostDemandMean),'\n']);
            fprintf(fid,['c ',curAct.name,' ',num2str(curAct.hostDemandSCV),'\n']);
            if strcmp(curAct.callOrder,'DETERMINISTIC')
                fprintf(fid,['f ',curAct.name,' 1\n']);
            else
                fprintf(fid,['f ',curAct.name,' 0\n']);
            end
            for d=1:numel(curAct.synchCallDests)
                fprintf(fid,['y ',curAct.name,' ',curAct.synchCallDests{d},' ',num2str(curAct.synchCallMeans),'\n']);
            end
            for d=1:numel(curAct.asynchCallDests)
                fprintf(fid,['z ',curAct.name,' ',curAct.asynchCallDests{d},' ',num2str(curAct.asynchCallMeans),'\n']);
            end            
        end
        buffer = '';
        for ap=1:length(curTask.precedences)
            curActPrec = self.processors(p).tasks(t).precedences(ap);
            preActName = curActPrec.pres{1};
            postActName = curActPrec.posts{1};
            for e=1:length(curTask.entries)
                curEntry = self.processors(p).tasks(t).entries(e);
                if any(strcmp(preActName,curEntry.replyActivity))
                    preActName = [preActName,'[',curEntry.name,']'];
                    break
                end
            end
            buffer = [buffer,preActName,' -> ',postActName,';\n'];
        end
        for e=1:length(curTask.entries)
            curEntry = self.processors(p).tasks(t).entries(e);
            for r=1:length(curEntry.replyActivity)
                replyActName = curEntry.replyActivity{r};
                replyActIndex = findstring(lqnGraph.Nodes.Node,replyActName);
                nextNodeIndices = successors(lqnGraph,replyActIndex);
                if ~any(strcmp(lqnGraph.Nodes.Type(nextNodeIndices),'AS'))
                    buffer = [buffer,replyActName,'[',curEntry.name,'];\n'];
                end
            end
        end
        if ~isempty(buffer)
            fprintf(fid,[':\n',buffer(1:end-3),'\n']);
        end
        fprintf(fid,['-1\n\n']);
    end
end

if fid~=1
    fclose(fid);
end
end
