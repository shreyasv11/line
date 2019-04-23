function node = getSink(self)
% NODE = GETSINK(SELF)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

idx = self.getIndexSinkNode;
if isempty(idx)
    %    warning('The model does not have a Sink station.');
    node = [];
    return;
end
node = self.nodes{idx};
end
