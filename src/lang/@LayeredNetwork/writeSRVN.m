function writeSRVN(self, filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
fid = fopen(filename,'w+');
%fid = 1;
fprintf(fid,'G\n');
fprintf(fid,['"',self.name,'"\n']);
fprintf(fid,[num2str(Solver.defaultOptions.iter_tol),'\n']);
fprintf(fid,[num2str(Solver.defaultOptions.iter_max),'\n']);
fprintf(fid,['-1\n\n']);

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
            fprintf(fid,['p ',curProc.name,' s','\n']);
        case SchedStrategy.RAND
            fprintf(fid,['p ',curProc.name,' r m ',num2str(curProc.multiplicity),'\n']);
        otherwise
            error('Unsupported scheduling policy.');
    end
end
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
                fprintf(fid,['t ',curTask.name,' r ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);%,' z ',num2str(curTask.thinkTimeMean),'\n']);
            case SchedStrategy.FCFS
                fprintf(fid,['t ',curTask.name,' f  ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            case SchedStrategy.HOL
                fprintf(fid,['t ',curTask.name,' h  ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            case {SchedStrategy.INF, SchedStrategy.PS, SchedStrategy.RAND, SchedStrategy.GPS, SchedStrategy.DPS}
                fprintf(fid,['t ',curTask.name,' n  ',entryList,' -1 ',curProc.name,' m ',num2str(curTask.multiplicity),'\n']);
            otherwise
                error('Unsupported scheduling policy.');
        end
    end
end
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
            %fprintf(fid,['s ',curEntry.name,' 0.0 -1\n']);
            for a=1:length(curTask.activities)
                curAct = self.processors(p).tasks(t).activities(a);
                if strcmp(curAct.boundToEntry,curEntry.name)
                    fprintf(fid,['A ',curEntry.name,' ',curAct.name,'\n']);
                end
            end
        end
    end
end

fprintf(fid,'-1\n\n#Activity blocks\n');
for p = 1:length(self.processors)
    curProc = self.processors(p);
    for t=1:length(curProc.tasks)
        curTask = self.processors(p).tasks(t);
        fprintf(fid,['A ',curTask.name,'\n']);
        % task activities
        for a=1:length(curTask.activities)
            curAct = self.processors(p).tasks(t).activities(a);
            fprintf(fid,['s ',curAct.name,' ',num2str(curAct.hostDemandMean),' \n']);
            for d=1:numel(curAct.synchCallDests)
                fprintf(fid,['y ',curAct.name,' ',curAct.synchCallDests{d},' ',num2str(curAct.synchCallMeans),' \n']);
            end
        end
        if ~strcmp(curTask.scheduling,'ref')
            fprintf(fid,[':']);
            for a=1:length(curTask.activities)
                curAct = self.processors(p).tasks(t).activities(a);
                if ~isempty(curAct.boundToEntry)
                    if a==length(curTask.activities)
                        fprintf(fid,['\n',curAct.name,' [',curAct.boundToEntry,']']);
                    else
                        fprintf(fid,['\n',curAct.name,' [',curAct.boundToEntry,'];']);
                    end
                end
            end
        end
        fprintf(fid,['\n-1\n\n']);
    end
end
if fid~=1
    fclose(fid);
end
end