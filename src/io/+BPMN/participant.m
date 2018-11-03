classdef participant < BPMN.baseElement
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
    name;                   % string
    processRef;             % the id of the corresponding process object (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = participant(id, name, processRef)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['participant_',id];
        elseif(nargin <= 2)
            disp('Not enough input arguments'); 
            processRef = ''; 
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
        obj.processRef = processRef;
    end
    
end
    
end