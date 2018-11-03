classdef intermediateThrowEvent < BPMN.throwEvent
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = intermediateThrowEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['intermediateThrowEvent_',id];
        end
        obj@BPMN.throwEvent(id,name); 
    end

end
    
end