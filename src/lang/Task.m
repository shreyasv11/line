classdef Task < LayeredNetworkElement
    % A software server in a LayeredNetwork.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        multiplicity;       %int
        scheduling;         %string
        thinkTime;
        thinkTimeMean;      %double
        thinkTimeSCV;       %double
        entries = [];
        activities = [];
        precedences = [];
        replyEntry;
    end
    
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Task(model, name, multiplicity, scheduling, thinkTime)
            % OBJ = TASK(MODEL, NAME, MULTIPLICITY, SCHEDULING, THINKTIME)
            
            if ~exist('name','var')
                error('Constructor requires to specify at least a name.');
            end
            obj@LayeredNetworkElement(name);
            
            if ~exist('multiplicity','var')
                multiplicity = 1;
            end
            if ~exist('scheduling','var')
                scheduling = SchedStrategy.INF;
            end
            if ~exist('thinkTime','var')
                thinkTime = Distrib.Zero;
            end
            
            obj.multiplicity = multiplicity;
            obj.scheduling = scheduling;
            obj.setThinkTime(thinkTime);
            model.objects.tasks{end+1} = obj;
        end
        
        function obj = on(obj, parent)
            % OBJ = ON(OBJ, PARENT)
            
            parent.addTask(obj);
        end
        
        function obj = setAsReferenceTask(obj)
            % OBJ = SETASREFERENCETASK(OBJ)
            
            obj.scheduling = SchedStrategy.REF;
        end
        
        function obj = setThinkTime(obj, thinkTime)
            % OBJ = SETTHINKTIME(OBJ, THINKTIME)
            
            if isnumeric(thinkTime)
                if thinkTime <= Distrib.Zero
                    obj.thinkTime = Immediate();
                    obj.thinkTimeMean = Distrib.Zero;
                    obj.thinkTimeSCV = Distrib.Zero;
                else
                    obj.thinkTime = Exp(1/thinkTime);
                    obj.thinkTimeMean = thinkTime;
                    obj.thinkTimeSCV = 1.0;
                end
            elseif isa(thinkTime,'Distrib')
                obj.thinkTime = thinkTime;
                obj.thinkTimeMean = thinkTime.getMean();
                obj.thinkTimeSCV = thinkTime.getSCV();
            end
        end
        
        %addEntry
        function obj = addEntry(obj, newEntry)
            % OBJ = ADDENTRY(OBJ, NEWENTRY)
            
            obj.entries = [obj.entries; newEntry];
        end
        
        %addActivity
        function obj = addActivity(obj, newAct)
            % OBJ = ADDACTIVITY(OBJ, NEWACT)
            
            newAct.setParent(obj.name);
            obj.activities = [obj.activities; newAct];
        end
        
        %setActivity
        function obj = setActivity(obj, newAct, index)
            % OBJ = SETACTIVITY(OBJ, NEWACT, INDEX)
            
            obj.activities(index,1) = newAct;
        end
        
        %removeActivity
        function obj = removeActivity(obj, index)
            % OBJ = REMOVEACTIVITY(OBJ, INDEX)
            
            idxToKeep = [1:index-1,index+1:length(obj.activities)];
            obj.activities = obj.activities(idxToKeep);
            obj.actNames = obj.actNames(idxToKeep);
        end
        
        %addPrecedence
        function obj = addPrecedence(obj, newPrec)
            % OBJ = ADDPRECEDENCE(OBJ, NEWPREC)
            
            if iscell(newPrec)
                for m=1:length(newPrec)
                    obj.precedences = [obj.precedences; newPrec{m}];
                end
            else
                obj.precedences = [obj.precedences; newPrec];
            end
        end
        
        %setReplyEntry
        function obj = setReplyEntry(obj, newReplyEntry)
            % OBJ = SETREPLYENTRY(OBJ, NEWREPLYENTRY)
            
            obj.replyEntry = newReplyEntry;
        end
        
        function meanHostDemand = getMeanHostDemand(obj, entryName)
            % MEANHOSTDEMAND = GETMEANHOSTDEMAND(OBJ, ENTRYNAME)
            
            % determines the demand posed by the entry entryName
            % the demand is located in the activity of the corresponding entry
            
            meanHostDemand = -1;
            for j = 1:length(obj.entries)
                if strcmp(obj.entries(j).name, entryName)
                    meanHostDemand = obj.entries(j).activities(1).hostDemandMean;
                    break;
                end
            end
        end
        
    end
    
end