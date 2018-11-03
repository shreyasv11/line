classdef SharedServer < Section
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        numberOfServers;
        serviceProcess;
    end
    
    methods
        %Constructor
        function self = SharedServer(customerClasses)
            self = self@Section('SharedServer');
            self.numberOfServers = 1;
            self.serviceProcess = {};
            initServers(self, customerClasses); %[JobClass(), ServiceStrategy.ID_LI, Distribution('exp')];
        end
    end
    
    methods (Access = 'private')
        function initServers(self, customerClasses)
           for i = 1 : length(customerClasses),
              self.serviceProcess{1, i} = {customerClasses{1, i}.name, ServiceStrategy.ID_LI, Exponential()};  
           end
        end
    end

	    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@matlab.mixin.Copyable(self);
            % Make a deep copy of each object
            for i=1:length(self.serviceProcess)
			if ishandle(self.serviceProcess{i}{3})
                clone.serviceProcess{i}{3} = self.serviceProcess{i}{3}.copy;
				end
            end
        end        
    end
end

