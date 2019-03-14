classdef intermediateCatchEvent < BPMN.catchEvent
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = intermediateCatchEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['intermediateCatchEvent_',id];
        end
        obj@BPMN.catchEvent(id,name); 
    end

end
    
end