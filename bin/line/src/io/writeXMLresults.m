%  WRITEXMLRESULTS writes the results of the analysis in an XML file
%  
%  Parameters: 
%  filenameLQN:  File path of the LQN XML file 
%  filenameRE:   File path of the EXT XML file 
%  myQN:        Queueing Network model used for analysis
%  util:         Utilization of each processor
%  XN:           Throughput for each job class
%  RT:           Total response time for each job class
%  RN:           Response time in each station (row) for each job class (col)
%  resEntries:      results (mean response time) for the entries in the LQN model
%  RT_CDF:       response time CDF for the main classes in the LQN
%  resEntries_CDF:  response time CDF for the entries in the LQN model
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
