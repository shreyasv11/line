classdef eventDefinition < BPMN.rootElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = eventDefinition(id)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        end
        obj@BPMN.rootElement(id); 
    end

end
    
end