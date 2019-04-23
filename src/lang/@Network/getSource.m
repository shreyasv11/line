function node = getSource(self)
% NODE = GETSOURCE(SELF)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

idx = self.getIndexSourceNode;
if isempty(idx)
    %    warning('The model does not have a Source station.');
    node = [];
    return
end
node = self.nodes{idx};
end
