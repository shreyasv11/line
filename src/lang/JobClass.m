classdef JobClass < Copyable
    % Copyright (c) 2012-2018, Imperial College London
    % All rights reserved.
    
    properties
        name;
        priority;
        reference; % reference station
        index;
        type;
        completes; % true if passage through reference station is a completion
    end
    
    methods (Hidden)
        %Constructor
        function self = JobClass(type, name)
            self.name = name;
            self.priority = 0;
            self.reference = Node('');
            self.index = 1;
            self.type=type;
            self.completes = true;
        end
        
        function self = setReferenceStation(self, source)
            self.reference = source;
        end
        
        function boolIsa = isReferenceStation(self, node)
            boolIsa = strcmp(self.reference.name,node.name);
        end
        
        
        %         function self = set.priority(self, priority)
        %             if ~(rem(priority,1) == 0 && priority >= 0)
        %                 error('Priority must be an integer.\n');
        %             end
        %             self.priority = priority;
        %         end
    end
    
    methods (Access=public)
        function ind = subsindex(self)
            ind = double(self.index)-1; % 0 based
        end
    end
    
end
