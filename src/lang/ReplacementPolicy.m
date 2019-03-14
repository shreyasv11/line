classdef (Sealed) ReplacementPolicy
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties (Constant)
        RAND = 'rand'; % random replacement
        FIFO = 'fifo';
        SFIFO = 'sfifo'; % strict fifo
        LRU = 'lru';
        
        ID_RAND = 0;
        ID_FIFO = 1;
        ID_SFIFO = 2; % strict fifo
        ID_LRU = 3;
    end
    
    methods (Static)
        function id = toId(type)
            switch type
                case ReplacementPolicy.RAND
                    id = ReplacementPolicy.ID_RAND;
                case ReplacementPolicy.FIFO
                    id = ReplacementPolicy.ID_FIFO;
                case ReplacementPolicy.SFIFO
                    id = ReplacementPolicy.ID_SFIFO;
                case ReplacementPolicy.LRU
                    id = ReplacementPolicy.ID_LRU;
            end
        end
        
        function property = toProperty(text)
            switch text
                case 'rand' % rrom replacement
                    property = 'RAND';
                case 'fifo'
                    property = 'FIFO';
                case 'strict-fifo'
                    property = 'SFIFO';
                case 'lru'
                    property = 'LRU';
            end
        end
        
        function text = toFeature(type)
            switch type
                case ReplacementPolicy.RAND
                    text = 'ReplacementPolicy_RAND';
                case ReplacementPolicy.FIFO
                    text = 'ReplacementPolicy_FIFO';
                case ReplacementPolicy.SFIFO
                    text = 'ReplacementPolicy_SFIFO';
                case ReplacementPolicy.LRU
                    text = 'ReplacementPolicy_LRU';
            end
        end
    end
end