classdef parallelGateway < BPMN.gateway
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = parallelGateway(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['parallelGateway_',id];
        end
        obj@BPMN.gateway(id,name); 
    end
    
    

end
    
end