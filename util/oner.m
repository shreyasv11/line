function [N]=oner(N,r)
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
for s=r(:)'
    if s~=0
        N(s)=N(s)-1;
    end
end
end

