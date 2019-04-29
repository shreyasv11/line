function r = multinomialln(m)
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
r = gammaln(1+sum(m));
    for i=1:length(m)
        r = r - gammaln(1+m(i));
    end
end