function S=cellsum(C)
% S=CELLSUM(C)
% Returns sum of non-empty elements in cell array C
%
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
S = 0*C{1};
for i=1:length(C)
    if ~isempty(C{i})
    S = S + C{i};
    end
end
end