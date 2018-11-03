classdef StatelessClassSwitch < ClassSwitchSection
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    methods
        %Constructor
        function self = StatelessClassSwitch(classes, csMatrix)
            self = self@ClassSwitchSection(classes, 'StatelessClassSwitch');            
            % this is slower than indexing the matrix, but it is a small
            % matrix anyway
            self.csFun = @(r,s,state,statep) csMatrix(r,s); % state parameter if present is ignored
        end
    end
        
end
