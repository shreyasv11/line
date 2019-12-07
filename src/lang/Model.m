classdef Model < Copyable
    % Abstract parent class for all models
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        name;
    end
    
    methods
        %Constructor
        function self = Model(name)
            % SELF = MODEL(NAME)
            
            self.setName(name);
        end
        
        function out = getName(self)
            % OUT = GETNAME()
            
            out = self.name;
        end
        
        function self = setName(self, name)
            % SELF = SETNAME(NAME)
            
            self.name = name;
        end
        
    end
    
end
