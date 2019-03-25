classdef server
    % Auxiliary data structure for stations in PMIF models
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        name;                 %string
        quantity = 1;         %int
        scheduling;           %string
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = server(name, quantity, scheduling)
            if(nargin > 0)
                obj.name = name;
                obj.quantity = quantity;
                obj.scheduling = scheduling;
            end
        end
        
    end
    
end