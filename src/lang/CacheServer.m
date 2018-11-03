classdef CacheServer < Section
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        classes;
        numberOfServers;
        numberOfLevels;
        serviceProcess;
        levelCapacities;
    end
    
    methods
        %Constructor
        function self = CacheServer(classes, levels, levelCapacities)
            self = self@Section('CacheServer');
            self.classes = classes;
            self.numberOfServers = 1;
            self.numberOfLevels = levels;
            self.serviceProcess = {};
            self.levelCapacities = levelCapacities;
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@matlab.mixin.Copyable(self);
            % Make a deep copy of each object
            for i = 1 : length(self.serviceProcess)
                if ishandle(clone.serviceProcess{1,i}{3})
                    % this is a problem if one modifies the classes in the
                    % model because the one below is not an handle so it
                    % will not be modified
                    clone.serviceProcess{1,i}{3} = self.serviceProcess{1,i}{3}.copy; 
                end
            end
        end
    end     
end