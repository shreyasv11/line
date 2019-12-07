classdef Entry < LayeredNetworkElement
    % An entry point of service for a Task.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        type;
        parent;
        activities = [];
        replyActivity = {};
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Entry(model, name, type)
            % OBJ = ENTRY(MODEL, NAME, TYPE)
            
            if ~exist('name','var')
                error('Constructor requires to specify at least a name.');
            end
            obj@LayeredNetworkElement(name);
            if ~exist('type','var')
                type = 'Graph';
            end
            obj.type = type;
            model.objects.entries{end+1} = obj;
        end
        
        function obj = on(obj, parent)
            % OBJ = ON(OBJ, PARENT)
            
            parent.addEntry(obj);
            obj.parent = parent;
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
