classdef Event < Copyable
    % A generic event occurring in a model.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    % event major classification
    
    properties
        node;
        event;
        class;
        prob;
        state;
    end
    
    methods
        function self = Event(event, node, class, prob, state)
            % SELF = EVENT(EVENT, NODE, CLASS, PROB, STATE)
            
            self.node = node;
            self.event = event;
            self.class = class;
            if ~exist('prob','var')
                prob = NaN;
            end
            self.prob = prob;
            if ~exist('state','var')
                state = []; % local state of the node
            end
            self.state = state;
        end
        
        function print(self)
            % PRINT()
            
            fprintf(1,'(%s: %d,%d)\n',EventType.toText(self.event),self.node,self.class);
        end
    end
    
    
end
