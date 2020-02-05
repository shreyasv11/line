classdef Entry < LayeredNetworkElement
    % An entry point of service for a Task.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        parent;
        replyActivity = {};
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Entry(model, name)
            % OBJ = ENTRY(MODEL, NAME)
            
            if ~exist('name','var')
                error('Constructor requires to specify at least a name.');
            end
            obj@LayeredNetworkElement(name);
            
            model.objects.entries{end+1} = obj;
        end
        
        function obj = on(obj, parent)
            % OBJ = ON(OBJ, PARENT)
            
            parent.addEntry(obj);
            obj.parent = parent;
        end
        
    end
    
end
