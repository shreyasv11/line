classdef activity < BPMN.flowNode
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    property;               % list of modeler-defined properties (cell of string)
    resourceRole;           % resources responsible for performing the activity - IDs (cell of string)
    loopCharacteristics;    % defines if and the activity is repeated - ID (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = activity(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['activity_',id];
        end
        obj@BPMN.flowNode(id,name); 
    end
    
    function obj = addProperty(obj, prop)
       if nargin > 1
            if isempty(obj.property)
                obj.property = cell(1);
                obj.property{1} = prop;
            else
                obj.property{end+1,1} = prop;
            end
       end
    end
    
    function obj = addResourceRole(obj, role)
       if nargin > 1
            if isempty(obj.resourceRole)
                obj.resourceRole = cell(1);
                obj.resourceRole{1} = role;
            else
                obj.resourceRole{end+1,1} = role;
            end
       end
    end
    
end
    
end