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
        RAND = 'Random';
        RR = 'RoundRobin';
        PROB = 'Probabilities';
        JSQ = 'JoinShortestQueue';
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
                case 0 % if unassigned, set it by default to Random
                    feature = 'RoutingStrategy_RAND';
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
                case 0 % if unassigned, set it by default to Random
                    text = 'Random';
            end
        end
    end
    
end

