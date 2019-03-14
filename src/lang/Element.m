classdef Element < Copyable
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        name;
    end
        
    methods
        %Constructor
        function self = Element(name)
            self.setName(name);
        end
        
        function out = getName(self)
            out = self.name;
        end
        
        function self = setName(self, name)
            self.name = name;
        end
      
    end
        
end