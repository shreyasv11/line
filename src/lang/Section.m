classdef Section < Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        className;
    end
    
    methods(Hidden)
        %Constructor
        function self = Section(className)
            self.className = className;
        end
    end
end
