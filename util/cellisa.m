function v=cellisa(c,className)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
v=cellfun(@(x) isa(x,className),c);
end