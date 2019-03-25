classdef Processor  < LayeredNetworkElement
% A hardware server in a LayeredNetwork.
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    ID;                 %int
    multiplicity;       %int
    scheduling;         %char: ps, fcfs, inf, ref
    quantum = 0;        %double
    speedFactor = 1;    %double
    tasks = [];         %list of classes
end

methods
%public methods, including constructor

    %constructor
    function obj = Processor(model, name, multiplicity, scheduling, quantum, speedFactor)
        if ~exist('name','var')
            error('Constructor requires to specify at least a name.');
        end
        obj@LayeredNetworkElement(name);
        
        if ~exist('multiplicity','var')
            multiplicity = 1;
        end
        if ~exist('scheduling','var')
            scheduling = SchedStrategy.PS;
        end
        if ~exist('quantum','var')
            quantum = 0.001;
        end
        if ~exist('speedFactor','var')
            speedFactor = 1;
        end
        
        obj.multiplicity = multiplicity;
        obj.scheduling = scheduling;
        obj.quantum = quantum;
        obj.speedFactor = speedFactor;
        model.objects.processors{end+1} = obj;
        if isempty(model.processors)
                model.processors = obj;
        else
                model.processors = [model.processors; obj];
        end
    end
    
    
    %addTask
    function obj = addTask(obj, newTask)
        if(nargin > 1)
            obj.tasks = [obj.tasks; newTask];
        end
    end
    
end
    
end