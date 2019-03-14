classdef (Sealed) SchedPolicy
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
    function out = SchedPolicy
    end 
end

methods (Static)
    
    function text = toText(type)
        switch type
            case SchedPolicy.NP
                text = 'NonPreemptive';
            case SchedPolicy.PNR
                text = 'PreemptiveNonResume';
            case SchedPolicy.PR
                text = 'PreemptiveResume';
            case SchedPolicy.NPPrio
                text = 'NonPreemptivePriority';
        end
    end
end


end

