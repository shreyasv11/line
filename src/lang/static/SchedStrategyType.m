classdef (Sealed) SchedStrategyType
    % Enumeration of scheduling strategy types
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        PR = 'PR'; % preemptive resume
        PNR = 'PRN'; % preemptive non-resume
        NP = 'NPR'; % non-preemptive
        NPPrio = 'NPPrio'; % non-preemptive priority
    end
    
    methods (Access = private)
        %private so that it cannot be instatiated.
        function out = SchedStrategyType
        end
    end
    
    methods (Static)
        
        function text = toText(type)
            switch type
                case SchedStrategyType.NP
                    text = 'NonPreemptive';
                case SchedStrategyType.PNR
                    text = 'PreemptiveNonResume';
                case SchedStrategyType.PR
                    text = 'PreemptiveResume';
                case SchedStrategyType.NPPrio
                    text = 'NonPreemptivePriority';
            end
        end
    end
end
