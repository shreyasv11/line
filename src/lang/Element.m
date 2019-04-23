classdef Element < Copyable
    % Abstract class for generic elements of a model.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        name;
    end
    
    methods
        %Constructor
        function self = Element(name)
            % SELF = ELEMENT(NAME)
            
            self.setName(name);
        end
        
        function out = getName(self)
            % OUT = GETNAME(SELF)
            
            out = self.name;
        end
        
        function self = setName(self, name)
            % SELF = SETNAME(SELF, NAME)
            
            self.name = name;
        end
        
    end
    
end
