classdef gateway < BPMN.flowNode
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    gatewayDirection;       % gateway direction (string): Unspecified - Diverging - Converging - Mixed 
end

methods
%public methods, including constructor

    %constructor
    function obj = gateway(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['gateway_',id];
        end
        obj@BPMN.flowNode(id,name); 
        obj.gatewayDirection = 'Unspecified'; 
    end
    
    function obj = setGatewayDirection(obj, dir)
        obj.gatewayDirection = dir;
    end

end
    
end