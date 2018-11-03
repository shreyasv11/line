%% EXAMPLE_PMIF_1 exemplifies the use of LINE to analize PMIF models.
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.


%% obtain CQN representation from PMIF description
verbose = 0;
cwd = fileparts(which('example_LINE_1.m'));
model = PMIF2LINE(fullfile(cwd,'data','PMIF','pmif_example_closed.xml'), verbose);
