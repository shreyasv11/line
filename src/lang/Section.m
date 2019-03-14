classdef Section < NetworkElement
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        className;
    end
    
    methods(Hidden)
        %Constructor
        function self = Section(className)
            self@NetworkElement('Section');
            self.className = className;
        end
    end
end
