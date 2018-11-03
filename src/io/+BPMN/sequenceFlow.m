classdef sequenceFlow < BPMN.flowElement
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
    sourceRef;              % the id of the corresponding process object (string)
    targetRef;              % the id of the corresponding process object (string)
    condExpression;         
end

methods
%public methods, including constructor

    %constructor
    function obj = sequenceFlow(id, name, sourceRef, targetRef)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['sequenceFlow_',id];
        elseif(nargin <= 2)
            disp('Not enough input arguments'); 
            sourceRef = '';
        elseif(nargin <= 3)
            disp('Not enough input arguments'); 
            targetRef = '';
        end
        obj@BPMN.flowElement(id,name);
        obj.sourceRef = sourceRef;
        obj.targetRef = targetRef;
    end
    
    function obj = addCondExpression(obj, id, type, value)
       if nargin == 4
            obj.condExpression = {id, type, value}; 
       end
    end

end
    
end