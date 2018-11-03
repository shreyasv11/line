function node = getSource(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

idx = self.getIndexSourceNode;
if isempty(idx)
%    warning('The model does not have a Source station.');
    node = [];
    return
end
node = self.nodes{idx};
end
