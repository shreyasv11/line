function Q=ctmc_makeinfgen(Q)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
A=Q-diag(diag(Q)); Q=A-diag(sum(A,2));
end