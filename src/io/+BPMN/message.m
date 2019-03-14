classdef message < BPMN.rootElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    name;                     % string
end

methods
%public methods, including constructor

    %constructor
    function obj = message(id,name)
        if(nargin == 0)
            disp('No ID provided for this message'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp(['No name provided for message ', id]); 
            name = ['message_',id];
        end
        obj@BPMN.rootElement(id); 
        obj.name = name;
    end

end
    
end