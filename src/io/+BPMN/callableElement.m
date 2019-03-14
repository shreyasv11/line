classdef callableElement < BPMN.rootElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    name;                   % string
    supportedInterfaceRef;  % IDs of supported interfaces (cell of string)
end

methods
%public methods, including constructor

    %constructor
    function obj = callableElement(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['callableElement_',id];
        end
        obj@BPMN.rootElement(id); 
        obj.name = name;
    end
    
    function obj = addSupportedInterfaceRef(obj, interface)
       if nargin > 1
            if isempty(obj.supportedInterfaceRef)
                obj.supportedInterfaceRef = cell(1);
                obj.supportedInterfaceRef{1} = interface;
            else
                obj.supportedInterfaceRef{end+1,1} = interface;
            end
       end
    end

end
    
end