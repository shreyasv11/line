function lqsimSolve(filename, maxTime)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
if ~exist('maxIter','var')
    system(['lqsim -T 1000000 -x ',filename]);
else
    system(['lqsim -T ',num2str(maxTime),' -x ',filename])
end
end