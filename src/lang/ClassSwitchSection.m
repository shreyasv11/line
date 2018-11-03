classdef ClassSwitchSection < Section
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        csFun;
        classes;
    end
    
    methods
        %Constructor
        function self = ClassSwitchSection(classes, name)
            self = self@Section(name);            
            self.classes = classes;
        end
    end
        
end
