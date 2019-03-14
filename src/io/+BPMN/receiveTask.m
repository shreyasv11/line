classdef receiveTask < BPMN.Task
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    implementation; % technology used to implement the Task (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = receiveTask(id, name, implementation)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['receiveTask_',id];
        elseif(nargin <= 2)
            disp(['No implementation specified for sendTask ',id]); 
            implementation = '';
        end
        obj@BPMN.Task(id,name); 
        obj.implementation = implementation;
    end
    
    function obj = setMessageRef(obj, msgRef)
        obj.messageRef = msgRef;
    end

end
    
end