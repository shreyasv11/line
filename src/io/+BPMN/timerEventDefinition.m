classdef timerEventDefinition < BPMN.eventDefinition
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties
    timeDuration;   % duration of the event (string - expression)
	timeDate;       % duration of the event (string - expression)
    timeCycle;      % duration of the event (string - expression)
end

methods
%public methods, including constructor

    %constructor
    function obj = timerEventDefinition(id)
        if(nargin == 0)
            disp('No ID provided for this timerEventDefinition'); 
            id = int2str(rand()); 
        end
        obj@BPMN.eventDefinition(id); 
    end
    
    function obj = setTimeDuration(obj, time)
        obj.timeDuration = time; 
        obj.timeDate  = []; 
        obj.timeCycle = []; 
    end
    
    function obj = setTimeDate(obj, time)
        obj.timeDuration = []; 
        obj.timeDate  = time; 
        obj.timeCycle = []; 
    end
    
    function obj = setTimeCycle(obj, time)
        obj.timeDuration = []; 
        obj.timeDate  = []; 
        obj.timeCycle = time; 
    end

end
    
end