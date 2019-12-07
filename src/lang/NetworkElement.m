classdef NetworkElement < Element
    % A generic element of a Network model.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    methods
        %Constructor
        function self = NetworkElement(name)
            % SELF = NETWORKELEMENT(NAME)
            
            self@Element(name);
        end
        
    end
    
end
