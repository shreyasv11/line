classdef resource < BPMN.baseElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    name;           % string
    multiplicity;   % int
    scheduling;     % string
    assignments;     % cell of strings - 2 cols
end

methods
%public methods, including constructor

    %constructor
    function obj = resource(id, name, multiplicity, scheduling)
        if(nargin == 0)
            disp('No ID provided for this resource'); 
            id = int2str(rand()); 
        end
        if(nargin <= 1)
            disp(['No name provided for resource with id ', id]); 
            name = ['resource_',id];
        end
        if(nargin <= 2)
            disp(['No multiplicity provided for resource with id ', id]); 
            multiplicity = 1;
        end
        if(nargin <= 3)
            disp(['No scheduling provided for resource with id ', id]); 
            scheduling = SchedStrategy.PS;
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
        obj.multiplicity = multiplicity;
        obj.scheduling = scheduling;
    end
    
    function obj = addAssignment(obj, taskID, meanExecTime)
       if nargin > 1
            if isempty(obj.assignments)
                obj.assignments = cell(1,2);
                obj.assignments{1,1} = taskID;
                obj.assignments{1,2} = meanExecTime;
            else
                obj.assignments{end+1,1} = taskID;
                obj.assignments{end,2} = meanExecTime; 
            end
       end
    end

end
    
end