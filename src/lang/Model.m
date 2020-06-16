classdef Model < Copyable
    % Abstract parent class for all models
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        name;
        lineVersion;
    end
    
    methods
        %Constructor
        function self = Model(name)
            % SELF = MODEL(NAME)
            %[~,lineVersion] = system('git describe'); 
            lineVersion = '2.0.7';
            lineVersion = strip(lineVersion);
            self.setVersion(lineVersion);
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
        
        function v = getVersion(self)
            v = self.version;
        end        
        
        function self = setVersion(self, version)
            % SELF = SETVERSION(VERSION)
            
            self.lineVersion = version;
        end
    end
    
end
