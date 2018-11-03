function LINE(config_file)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

fprintf(1,'\n------------------------------------------------\n');
fprintf(1,'LINE\nPerformance and Reliability Analysis Engine\n');
fprintf(1,'Copyright (c) 2012-2018, Imperial College London\n');
fprintf(1,'All rights reserved.\n');
fprintf(1,'------------------------------------------------\n');

setmcruserdata('ParallelProfile', 'lineClusterProfile.settings');
LINEserver(config_file)
end