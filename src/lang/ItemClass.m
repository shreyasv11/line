classdef ItemClass < NetworkElement
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    properties
        name;
        nitems;
        index;
        reference;
        replicable;
    end
    
    methods
        function self = ItemClass(model, name, nitems, reference)
            self.name = name;
            self.nitems = nitems;
            self.index = 1;
            self.replicable = false;
            if ~isa(reference, 'Cache')
                error('ItemClass must be pinned to a Cache.');
            end
            self.reference = reference;
            model.addItemClass(self);
        end
        
        function name = getName(self)
            name = self.name;
        end
        
        function bool = hasReplicableItems(self)
            bool = self.replicable;
        end
        
        function ntypes = getNumberOfItems(self)
            ntypes = self.nitems;
        end
    end
end