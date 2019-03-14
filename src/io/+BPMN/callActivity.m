classdef callActivity < activity
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    calledElement;      % ID of the element called by this activity, a process or a global task (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = callActivity(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['task_',id];
        end
        obj@activity(id,name); 
    end
    
    function obj = setCalledElement(obj, elem)
        obj.callElement = elem; 
    end

end
    
end