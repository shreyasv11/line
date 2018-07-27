%  [Q, U, R, X] = QN_Cox_fluid_analysis(A) computes the stationary performance
%  measures of a Closed Multi-Class Queueing Network with Class Switching
%  and Cox processing time (CQN) A.
%  More details on this type of queueing networks can be found
%  on the LINE documentation
% 
%  Parameters:
%  myQN:         a QNCoxCS model to analyze
%  options:      options data structure
% 
%  Ouput:
%  Q:            mean queue-length for each station and job class
%  U:            utilization for each server
%  R:            response time for each job class
%  X:            throughput for each job class
%  resEntry:      results (mean response time) for the entries defined in the LQN model
%  RT_CDF:       response time CDF for the main classes in the LQN
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
