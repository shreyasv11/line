classdef LogTunnel < ServiceSection
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

properties
    end
    
    methods
        %Constructor
        function self = LogTunnel()
            self = self@ServiceSection('LogTunnel');
            self.numberOfServers = 1;
            self.serviceProcess = {};
        end
    end
    
end

