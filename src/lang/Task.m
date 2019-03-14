classdef Task < LayeredElement
    
    properties
        multiplicity;       %int
        scheduling;         %string
        thinkTime;          %double
        thinkTimeMean;          %double
        thinkTimeSCV;          %double
        entries = [];
        activities = Activity.empty();     %task-activities
        initActID = 0;       %integer that indicates which is the initial activity
        precedences = [];
        replyEntry;
    end
    
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Task(model, name, multiplicity, scheduling, thinkTime)
            if ~exist('name','var')
                error('Constructor requires to specify at least a name.');
            end
            obj@LayeredElement(name);
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
            switch scheduling
                case SchedStrategy.REF
                    if ~isfinite(multiplicity)
                        obj.multiplicity = 1;
                    end
                    if isnumeric(thinkTime)
                        obj.thinkTimeMean = Exp(1/thinkTime);
                        obj.thinkTimeMean = thinkTime;
                        obj.thinkTimeSCV = 1.0;
                    elseif isa(thinkTime,'Distrib')
                        obj.thinkTime = thinkTime;
                        obj.thinkTimeMean = thinkTime.getMean();
                        obj.thinkTimeSCV = thinkTime.getSCV();
                    end
                otherwise
                    if strcmp(SchedStrategy.INF,scheduling) && isfinite(multiplicity)
                        obj.multiplicity = 1;
                    end
                    
                    obj.thinkTime = Exp(Inf);
                    obj.thinkTimeMean = 0.0;
                    obj.thinkTimeSCV = 0.0;
                    if thinkTime > 0
                        warning('Cannot specify a think time for a non-reference task, setting it to zero.');
                    end
            end
            model.objects.tasks{end+1} = obj;
        end
        
        function obj = on(obj, parent)
            parent.addTask(obj);
        end
        
        function obj = setAsReferenceTask(obj)
            self.scheduling = SchedStrategy.REF;
        end
        
        function obj = setThinkTime(obj, thinkTime)
            if isnumeric(thinkTime)
                obj.thinkTimeMean = Exp(1/thinkTime);
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
            if(nargin > 1)
                obj.entries = [obj.entries; newEntry];
            end
        end
        
        %addActivity
        function obj = addActivity(obj, newAct)
            if(nargin > 1)
                newAct.setParent(obj.name);
                obj.activities = [obj.activities; newAct];
            end
        end
        
        %setActivity
        function obj = setActivity(obj, newAct, index)
            if(nargin > 2)
                %if length(obj.activities) < index
                %    obj.activities = [obj.activities; LayeredNetwork.Activity.empty(index-length(obj.activities),0)];
                %end
                obj.activities(index,1) = newAct;
            end
        end
        
        %remove activity
        function obj = removeActivity(obj, index)
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
            if(nargin > 1)
                obj.initActID = initActID;
            end
        end
        
        %set
        function obj = addPrecedence(obj, newPrec)
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
            if(nargin > 1)
                obj.replyEntry = newReplyEntry;
            end
        end
        
        function meanHostDemand = getMeanHostDemand(obj, entryName)
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