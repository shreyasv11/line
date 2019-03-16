classdef Ensemble < Model
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        ensemble;
    end
    
    methods
        function self = Ensemble(models)
            self@Model('Ensemble');
            self.ensemble = reshape(models,1,numel(models)); % flatten 
        end
        
        function self = setEnsemble(self,ensemble)
            self.ensemble = ensemble;
        end
        
        function ensemble = getEnsemble(self)
            ensemble = self.ensemble;
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each ensemble object
            for e=1:length(self.ensemble)
                clone.ensemble{e} = copy(self.ensemble{e});
            end
        end
    end
end