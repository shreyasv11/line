classdef event < BPMN.flowNode
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    property;       % list of modeler-defined properties (cell of string)
end

methods
%public methods, including constructor

    %constructor
    function obj = event(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['event_',id];
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

end
    
end