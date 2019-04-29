function r=nchoosekln(n,m)
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
r=gammaln(1+n)-gammaln(1+(n-m))-gammaln(1+m);
end
