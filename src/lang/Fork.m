classdef Fork < Station
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

% ForkStation is regarded as a station because, while jobs would not
% station inside the fork node, the user may be interested to the number of 
% currently forked jobs. The number of jobs in the ForkStation is 
% interpreted as the job count in the Fork-Join subnetwork.

    properties
        schedStrategy;
    end
    
    methods
        %Constructor
        function self = Fork(model, name)
            self = self@Station(name);
            self.numberOfServers = 0;
            if(model ~= 0)
                classes = model.classes;
                self.input = Buffer(classes);
                self.cap = Inf;
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
