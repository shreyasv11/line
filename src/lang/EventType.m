classdef EventType < Copyable
    % Types of events 
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    % event major classification
    properties (Constant)
        INIT = -1; % model is initialized (t=0)
        LOCAL = 0;
        ARV = 1; % job arrival
        DEP = 2; % job departure
        PHASE = 3; % service advances to next phase, without departure
        READ = 4; % read cache item
    end
    
    methods(Static)
        function text = toText(type)
            % TEXT = TOTEXT(TYPE)
            
            switch type
                case EventType.ARV
                    text = 'ARV';
                case EventType.DEP
                    text = 'DEP';
                case EventType.PHASE
                    text = 'PHASE';
                case EventType.READ
                    text = 'READ';
            end
        end
    end
    
end
