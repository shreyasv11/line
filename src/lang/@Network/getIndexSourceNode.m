function index = getIndexSourceNode(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

index = find(cellisa(self.nodes,'Source'));
end
