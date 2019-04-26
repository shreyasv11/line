function index = getIndexSinkNode(self)
% INDEX = GETINDEXSINKNODE()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

index = find(cellisa(self.nodes,'Sink'));
end
