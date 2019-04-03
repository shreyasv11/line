classdef QueueingStation < Queue
    % Alias for the Queue class
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = QueueingStation(model, name, schedStrategy)
            self@Queue(model, name, schedStrategy);
        end
    end
end
