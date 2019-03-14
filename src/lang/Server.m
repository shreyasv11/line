classdef Server < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        numberOfServers;
        serviceProcess;
    end
    
    methods
        %Constructor
        function self = Server(classes)
            self = self@Section('Server');
            self.numberOfServers = 1;
            self.serviceProcess = {};
            initServers(self, classes); 
        end
    end
    
    methods (Access = 'private')
        function initServers(self, classes)
            for i = 1 : length(classes)
                self.serviceProcess{1, i} = {classes{i}.name, ServiceStrategy.ID_LI, Exp(0.0)};
            end
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
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

