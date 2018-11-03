classdef (Sealed) NodeType
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

properties (Constant)
    Dispatcher = 6;
    Cache = 5;
    Logger = 4;
    ClassSwitch = 3;
    Delay = 2;
    Queue = 0;
    Source = 1;
    Sink = -1;
end

methods (Static)
    function bool = isStation(nodetype)
        bool = (nodetype == NodeType.Source | nodetype == NodeType.Delay | nodetype == NodeType.Queue);
    end
    function bool = isStateful(nodetype)
        bool = (nodetype == NodeType.Source | nodetype == NodeType.Delay | nodetype == NodeType.Queue | nodetype == NodeType.Cache);
    end
end

end