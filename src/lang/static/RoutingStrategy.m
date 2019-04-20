classdef (Sealed) RoutingStrategy
    % Enumeration of routing strategies
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        ID_RAND = 0;
        ID_PROB = 1;
        ID_RR = 2;
        ID_JSQ = 3;
        ID_DISABLED = -1;
        RAND = 'Random';
        RR = 'RoundRobin';
        PROB = 'Probabilities';
        JSQ = 'JoinShortestQueue';
        DISABLED = 'Disabled';
    end
    
    methods (Static, Access = public)
        function type = toType(text)
            switch text
                case 'Random'
                    type = RoutingStrategy.RAND;
                case 'RoundRobin'
                    type = RoutingStrategy.RR;
                case 'Probabilities'
                    type = RoutingStrategy.PROB;
                case 'JoinShortestQueue'
                    type = RoutingStrategy.JSQ;
                case 'Disabled'
                    type = RoutingStrategy.DISABLED;
            end
        end
        
        function feature = toFeature(type)
            switch type
                case RoutingStrategy.RAND
                    feature = 'RoutingStrategy_RAND';
                case RoutingStrategy.RR
                    feature = 'RoutingStrategy_RR';
                case RoutingStrategy.PROB
                    feature = 'RoutingStrategy_PROB';
                case RoutingStrategy.JSQ
                    feature = 'RoutingStrategy_JSQ';
                case RoutingStrategy.DISABLED
                    feature = 'RoutingStrategy_DISABLED';
                case 0 % if unassigned, set it by default to Disabled
                    feature = 'RoutingStrategy_DISABLED';
            end
        end
        
        function text = toText(type)
            switch type
                case RoutingStrategy.RAND
                    text = 'Random';
                case RoutingStrategy.RR
                    text = 'RoundRobin';
                case RoutingStrategy.PROB
                    text = 'Probabilities';
                case RoutingStrategy.JSQ
                    text = 'JoinShortestQueue';
                case RoutingStrategy.DISABLED
                    text = 'Disabled';
                case 0 % if unassigned, set it by default to Disabled
                    text = 'Disabled';
            end
        end
    end
    
end

