classdef ServiceTunnel < ServiceSection
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    methods
        %Constructor
        function self = ServiceTunnel()
            self = self@ServiceSection('ServiceTunnel');
            self.numberOfServers = 1;
            self.serviceProcess = {};
        end
    end
    
end

