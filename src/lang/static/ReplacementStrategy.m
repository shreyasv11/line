classdef (Sealed) ReplacementStrategy
    % Enumeration of cache replacement strategies
    %
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
            % ID = TOID(TYPE)
            
            switch type
                case ReplacementStrategy.RAND
                    id = ReplacementStrategy.ID_RAND;
                case ReplacementStrategy.FIFO
                    id = ReplacementStrategy.ID_FIFO;
                case ReplacementStrategy.SFIFO
                    id = ReplacementStrategy.ID_SFIFO;
                case ReplacementStrategy.LRU
                    id = ReplacementStrategy.ID_LRU;
            end
        end
        
        function property = toProperty(text)
            % PROPERTY = TOPROPERTY(TEXT)
            
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
            % TEXT = TOFEATURE(TYPE)
            
            switch type
                case ReplacementStrategy.RAND
                    text = 'ReplacementStrategy_RAND';
                case ReplacementStrategy.FIFO
                    text = 'ReplacementStrategy_FIFO';
                case ReplacementStrategy.SFIFO
                    text = 'ReplacementStrategy_SFIFO';
                case ReplacementStrategy.LRU
                    text = 'ReplacementStrategy_LRU';
            end
        end
    end
end
