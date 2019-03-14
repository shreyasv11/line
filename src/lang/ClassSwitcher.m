classdef ClassSwitcher < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        csFun;
        classes;
    end
    
    methods
        %Constructor
        function self = ClassSwitcher(classes, name)
            self = self@Section(name);            
            self.classes = classes;
        end
    end
        
end
