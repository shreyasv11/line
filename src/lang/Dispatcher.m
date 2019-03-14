classdef Dispatcher < Section
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        outputStrategy;
    end
        
    methods
        %Constructor
        function self = Dispatcher(customerClasses)
            self = self@Section('Dispatcher');
            self.outputStrategy = {};
            initDispatcherJobClasses(self, customerClasses);
     end
    end
    
    methods
        function initDispatcherJobClasses(self, customerClasses)
            for r = 1 : length(customerClasses)
                self.outputStrategy{r} = {customerClasses{r}.name, RoutingStrategy.ID_RAND};
            end
        end
        
        function setStrategy(self, customerClasses, strategy)
            if length(strategy) == 1
                self.outputStrategy{customerClasses{r}.index} = {customerClasses{r}.name, strategy};
            else
                for r = 1 : length(customerClasses)
                    self.outputStrategy{customerClasses{r}.index} = {customerClasses{r}.name, strategy{r}};
                end
            end
        end
    end
    
end
