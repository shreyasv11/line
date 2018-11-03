classdef inclusiveGateway < BPMN.gateway
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
    default;        % ID of the default outgoing sequence flow (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = inclusiveGateway(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['exclusiveGateway_',id];
        end
        obj@BPMN.gateway(id,name); 
    end
    
    function obj = setDefault(obj, flowID)
       obj.default = flowID;
    end

end
    
end