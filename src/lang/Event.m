classdef Event < Copyable
    % Copyright (c) 2012-2018, Imperial College London
    % All rights reserved.
    
    % event major classification
    properties (Constant)
        LOCAL = 0;
        ARV = 1; % job arrival
        DEP = 2; % job departure
        PHASE = 3; % service advances to next phase, without departure
        READ = 4; % read cache item
    end
    
    properties
        node;
        event;
        class;
        prob;
        state;
    end
    
    methods
        function self = Event(event, node, class, prob, state)
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
            fprintf(1,'(%s: %d,%d)\n',Event.toText(self.event),self.node,self.class);
        end
    end
    
    methods(Static)
        function text = toText(type)
            switch type
                case Event.ARV
                    text = 'arv';
                case Event.DEP
                    text = 'dep';
                case Event.PHASE
                    text = 'phase';
                case Event.READ
                    text = 'read';
            end
        end
    end
    
end