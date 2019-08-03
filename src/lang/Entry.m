classdef Entry < LayeredNetworkElement
    % An entry point of service for a Task.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        type;
        parent;
        extArrival;          %double
        extArrivalMean;      %double
        extArrivalSCV;       %double
        activities = [];
        replyActivity = {};
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Entry(model, name, type, extArrival)
            % OBJ = ENTRY(MODEL, NAME, TYPE, EXTARRIVAL)
            
            if ~exist('name','var')
                error('Constructor requires to specify at least a name.');
            end
            obj@LayeredNetworkElement(name);
            if ~exist('type','var')
                type = 'Graph';
            end
            obj.type = type;
            if ~exist('extArrival','var')
                extArrival = NaN;
            end
            if isnumeric(extArrival)
                obj.extArrival = Exp(1/extArrival);
                obj.extArrivalMean = extArrival;
                obj.extArrivalSCV = 1.0;
            elseif isa(extArrival,'Distrib')
                obj.extArrival = extArrival;
                obj.extArrivalMean = extArrival.getMean();
                obj.extArrivalSCV = extArrival.getSCV();
            end
            model.objects.entries{end+1} = obj;
        end
        
        function obj = on(obj, parent)
            % OBJ = ON(OBJ, PARENT)
            
            parent.addEntry(obj);
            obj.parent = parent;
        end
        
        function obj = setExternalArrival(obj, extArrival)
            % OBJ = SETEXTERNALARRIVAL(OBJ, EXTARRIVAL)
            
            if isnumeric(extArrival) % assume this is a mean
                obj.extArrival = Exp(1 / extArrival);
                obj.extArrivalMean = extArrival;
                obj.extArrivalSCV = 1.0;
            elseif isa(extArrival,'Distrib')
                obj.extArrival = extArrival;
                obj.extArrivalMean = extArrival.getMean();
                obj.extArrivalSCV = extArrival.getSCV();
            end
        end
        
        %addActivity
        function obj = addActivity(obj, newActivity)
            % OBJ = ADDACTIVITY(OBJ, NEWACTIVITY)
            
            if(nargin > 1)
                newActivity.setParent(obj.name);
                obj.activities = [obj.activities; newActivity];
            end
        end
        
    end
    
end
