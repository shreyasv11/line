classdef Fork < Node
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

    properties
        schedStrategy;
    end
    
    methods
        %Constructor
        function self = Fork(model, name)
            self = self@Node(name);
            if(model ~= 0)
                classes = model.classes;
                self.input = Buffer(classes);
                self.schedStrategy = SchedStrategy.FORK;
                self.server = ServiceTunnel();
                self.output = Fork(classes);
                addNode(model, self);
            end
        end
           
        function setTasksPerLink(self, nTasks)
            self.output.tasksPerLink = nTasks;
        end
    end
    
end
