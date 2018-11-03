function idx=hashpop(n,N,R,prods)
% idx=hashpop(n,N)
% idx=hashpop(n,N,R,prods) where prods(r)=prod(N(1:r-1)+1) (faster)
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
idx=1;
if nargin==2
    R=length(N);
    for r=1:R
        idx= idx + prod(N(1:r-1)+1)*n(r);
    end
return
else
    for r=1:R
        idx= idx + prods(r)*n(r);
    end
end
end