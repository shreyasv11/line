function model = PMIF2LINE(filename,modelName)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
verbose = false;
qn = PMIF2QN(filename,verbose);
model = QN2LINE(qn, modelName);
end