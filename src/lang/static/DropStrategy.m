classdef (Sealed) DropStrategy
    % Enumeration of drop policies in stations.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        InfiniteBuffer = -1;
        Drop = 1;
        BlockingAfterService = 2;
    end
    
end

