classdef (Sealed) SchedStrategy
    % Enumeration of scheduling strategies
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        INF = 'inf'; % infinite server
        FCFS = 'fcfs';
        LCFS = 'lcfs';
        RAND = 'rand';
        SJF = 'sjf';
        LJF = 'ljf';
        PS = 'ps'; % egalitarian PS
        DPS = 'dps';
        GPS = 'gps';
        SEPT = 'sept';
        LEPT = 'lept';
        HOL = 'hol';
        FORK = 'fork';
        EXT = 'ext'; % external world (open arrival source and sink)
        REF = 'ref'; % reference node in LayeredNetworks        
        
        ID_INF = 0;
        ID_FCFS = 1;
        ID_LCFS = 2;
        ID_RAND = 3;
        ID_SJF = 4;
        ID_LJF = 5;
        ID_PS = 6;
        ID_DPS = 7;
        ID_GPS = 8;
        ID_SEPT = 9;
        ID_LEPT = 10;
        ID_HOL = 11;
        ID_FORK = 12;
        ID_EXT = 13;
        ID_REF = 14;        
    end
    
    methods (Static)
        function id = toId(type)
            % ID = TOID(TYPE)
            
            switch type
                case SchedStrategy.INF
                    id = 0;
                case SchedStrategy.FCFS
                    id = 1;
                case SchedStrategy.LCFS
                    id = 2;
                case SchedStrategy.RAND
                    id = 3;
                case SchedStrategy.SJF
                    id = 4;
                case SchedStrategy.LJF
                    id = 5;
                case SchedStrategy.PS
                    id = 6;
                case SchedStrategy.DPS
                    id = 7;
                case SchedStrategy.GPS
                    id = 8;
                case SchedStrategy.SEPT
                    id = 9;
                case SchedStrategy.LEPT
                    id = 10;
                case SchedStrategy.HOL
                    id = 11;
                case SchedStrategy.FORK
                    id = 12;
                case SchedStrategy.EXT
                    id = 13;
                case SchedStrategy.REF
                    id = 14;
            end
        end
        
        function property = toProperty(text)
            % PROPERTY = TOPROPERTY(TEXT)
            
            switch text
                case 'inf'
                    property = 'INF';
                case 'fcfs'
                    property = 'FCFS';
                case 'lcfs'
                    property = 'LCFS';
                case 'rand'
                    property = 'RAND';
                case 'sjf'
                    property = 'SJF';
                case 'ljf'
                    property = 'LJF';
                case 'ps'
                    property = 'PS';
                case 'dps'
                    property = 'DPS';
                case 'gps'
                    property = 'GPS';
                case 'sept'
                    property = 'SEPT';
                case 'lept'
                    property = 'LEPT';
                case 'hol'
                    property = 'HOL';
                case 'ext'
                    property = 'EXT';
                case 'fork'
                    property = 'FORK';
                case 'ref'
                    property = 'REF';
                case 'ext'
                    property = 'EXT';
            end
            
        end
        
        function text = toFeature(type)
            % TEXT = TOFEATURE(TYPE)
            
            switch type
                case SchedStrategy.INF
                    text = 'SchedStrategy_INF';
                case SchedStrategy.FCFS
                    text = 'SchedStrategy_FCFS';
                case SchedStrategy.LCFS
                    text = 'SchedStrategy_LCFS';
                case SchedStrategy.RAND
                    text = 'SchedStrategy_RAND';
                case SchedStrategy.SJF
                    text = 'SchedStrategy_SJF';
                case SchedStrategy.LJF
                    text = 'SchedStrategy_LJF';
                case SchedStrategy.PS
                    text = 'SchedStrategy_PS';
                case SchedStrategy.DPS
                    text = 'SchedStrategy_DPS';
                case SchedStrategy.GPS
                    text = 'SchedStrategy_GPS';
                case SchedStrategy.SEPT
                    text = 'SchedStrategy_SEPT';
                case SchedStrategy.LEPT
                    text = 'SchedStrategy_LEPT';
                case SchedStrategy.HOL
                    text = 'SchedStrategy_HOL';
                case SchedStrategy.FORK
                    text = 'SchedStrategy_FORK';
                case SchedStrategy.EXT
                    text = 'SchedStrategy_EXT';
                case SchedStrategy.REF
                    text = 'SchedStrategy_REF';
            end
        end
    end
    
end
