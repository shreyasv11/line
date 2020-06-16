classdef Host  < LayeredNetworkElement
    % A hardware server in a LayeredNetwork.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        multiplicity;       %int
        scheduling;         %char: ps, fcfs, inf, ref
        quantum;            %double
        speedFactor;        %double
        tasks = [];         %list of tasks
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Host(model, name, multiplicity, scheduling, quantum, speedFactor)
            % OBJ = HOST(MODEL, NAME, MULTIPLICITY, SCHEDULING, QUANTUM, SPEEDFACTOR)
            
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
            model.hosts{end+1} = obj;
        end
        
        
        %addTask
        function obj = addTask(obj, newTask)
            % OBJ = ADDTASK(OBJ, NEWTASK)
            obj.tasks = [obj.tasks; newTask];            
        end
        
    end
    
end
