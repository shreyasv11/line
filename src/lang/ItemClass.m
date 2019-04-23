classdef ItemClass < NetworkElement
    % A class of cacheable items
    %
    % Copyright (c) 2012-2019, Imperial College London
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
            % SELF = ITEMCLASS(MODEL, NAME, NITEMS, REFERENCE)
            
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
            % NAME = GETNAME(SELF)
            
            name = self.name;
        end
        
        function bool = hasReplicableItems(self)
            % BOOL = HASREPLICABLEITEMS(SELF)
            
            bool = self.replicable;
        end
        
        function ntypes = getNumberOfItems(self)
            % NTYPES = GETNUMBEROFITEMS(SELF)
            
            ntypes = self.nitems;
        end
    end
end
