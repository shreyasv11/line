classdef collaboration < BPMN.rootElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    name;                   % string
    participant;           % participants in the collaboration (array of particpants)
    messageFlow;           % message flows in the collaboration
    process;              % list of process objects participating in the collaboration
end

methods
%public methods, including constructor

    %constructor
    function obj = collaboration(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['collaboration_',id];
        end
        obj@BPMN.rootElement(id); 
        obj.name = name;
        obj.participant = [];
    end
    
    function obj = addParticipant(obj, participant)
        if isempty(obj.participant)
            obj.participant = participant;
        else
           obj.participant(end+1) = participant; 
        end
    end
    
    function obj = addProcess(obj, process)
        if isempty(obj.process)
            obj.process = process;
        else
            obj.process(end+1) = process; 
        end
    end
    
    function obj = addMessageFlow(obj, msgFlow)
        if isempty(obj.messageFlow)
            obj.messageFlow = msgFlow;
        else
            obj.messageFlow(end+1) = msgFlow; 
        end
    end

end
    
end