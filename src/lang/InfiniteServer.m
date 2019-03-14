classdef InfiniteServer < Section
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        numberOfServers;
        serviceProcess;
    end
    
    methods
        %Constructor
        function self = InfiniteServer(customerClasses)
            self = self@Section('InfiniteServer');
            self.numberOfServers = Inf;
            self.serviceProcess = {};
            initServers(self, customerClasses); 
        end
    end
    
    methods (Access = 'private')
        function initServers(self, customerClasses)
           for i = 1 : length(customerClasses),
              self.serviceProcess{1, i} = {customerClasses{1, i}.name, ServiceStrategy.ID_LI, Exp(0.0)};  
           end
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            for i=1:length(self.serviceProcess)
			if ishandle(self.serviceProcess{i}{3})
                clone.serviceProcess{i}{3} = self.serviceProcess{i}{3}.copy;
            end
			end
        end        
    end
    
end

