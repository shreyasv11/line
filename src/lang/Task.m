classdef Task < LayeredNetworkElement
    % A software server in a LayeredNetwork.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        multiplicity;       %int
        scheduling;         %string
        thinkTime;          %double
        thinkTimeMean;      %double
        thinkTimeSCV;       %double
        entries = [];
        activities = Activity.empty();     %task-activities
        initActID = 0;      %integer that indicates which is the initial activity
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
                thinkTime = NaN;
            end
            obj.multiplicity = multiplicity;
            obj.scheduling = scheduling;
            if isnumeric(thinkTime)
                obj.thinkTime = Exp(1/thinkTime);
                obj.thinkTimeMean = thinkTime;
                obj.thinkTimeSCV = 1.0;
            elseif isa(thinkTime,'Distrib')
                obj.thinkTime = thinkTime;
                obj.thinkTimeMean = thinkTime.getMean();
                obj.thinkTimeSCV = thinkTime.getSCV();
            end
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
                obj.thinkTime = Exp(1/thinkTime);
                obj.thinkTimeMean = thinkTime;
                obj.thinkTimeSCV = 1.0;
            elseif isa(thinkTime,'Distrib')
                obj.thinkTime = thinkTime;
                obj.thinkTimeMean = thinkTime.getMean();
                obj.thinkTimeSCV = thinkTime.getSCV();
            end
        end
        
        %addEntry
        function obj = addEntry(obj, newEntry)
            % OBJ = ADDENTRY(OBJ, NEWENTRY)
            
            if(nargin > 1)
                obj.entries = [obj.entries; newEntry];
            end
        end
        
        %addActivity
        function obj = addActivity(obj, newAct)
            % OBJ = ADDACTIVITY(OBJ, NEWACT)
            
            if(nargin > 1)
                newAct.setParent(obj.name);
                obj.activities = [obj.activities; newAct];
            end
        end
        
        %setActivity
        function obj = setActivity(obj, newAct, index)
            % OBJ = SETACTIVITY(OBJ, NEWACT, INDEX)
            
            if(nargin > 2)
                %if length(obj.activities) < index
                %    obj.activities = [obj.activities; LayeredNetwork.Activity.empty(index-length(obj.activities),0)];
                %end
                obj.activities(index,1) = newAct;
            end
        end
        
        %remove activity
        function obj = removeActivity(obj, index)
            % OBJ = REMOVEACTIVITY(OBJ, INDEX)
            
            if(nargin > 1)
                if length(obj.activities) < index
                    % throw exception - attempted to remove unexisting activity
                    errID = 'LQN:Task:NonExistingActivity';
                    errMsg = 'LQN Task %s has %d activities, but activity %d was tried to me removed.';
                    err = MException(errID, errMsg, obj.name, length(obj.activities), index);
                    throw(err)
                else
                    idxToKeep = [1:index-1 index+1:length(obj.activities)];
                    obj.activities = obj.activities(idxToKeep);
                    obj.actNames = obj.actNames(idxToKeep);
                end
            end
        end
        
        %setInitActivity
        function obj = setInitActivity(obj, initActID)
            % OBJ = SETINITACTIVITY(OBJ, INITACTID)
            
            if(nargin > 1)
                obj.initActID = initActID;
            end
        end
        
        %set
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
            
            if(nargin > 1)
                obj.replyEntry = newReplyEntry;
            end
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
