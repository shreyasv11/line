classdef messageEventDefinition < BPMN.eventDefinition
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    messageRef;     % ID of the message referenced by the event (string)
    operationRef;   % operation used by the message (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = messageEventDefinition(id)
        if(nargin == 0)
            disp('No ID provided for this messageEventDefinition'); 
            id = int2str(rand()); 
        end
        obj@BPMN.eventDefinition(id); 
    end
    
    function obj = setMessageRef(obj, msgRef)
        obj.messageRef = msgRef; 
    end

    function obj = setOperationRef(obj, operRef)
        obj.operationRef = operRef; 
    end

end
    
end