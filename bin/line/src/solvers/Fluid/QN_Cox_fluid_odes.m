%  QN_Cox_fluid_ODES provides the methods to perform the ODE
%  analysis of a Closed Multi-Class Queueing Network with Class Switching
%  and with Cox Service Times (QNCox).
%  More details on this type of queueing networks can be found
%  in the LINE documentation
% 
%  Parameters:
%  N:    total number of jobs
%  Mu:   service rates in each station (in each phase), for each stage
%  Phi:  probability of service completion in each stage of the service
%        process in each station, for each stage
%  P:    routing matrix for each stage
%  S:    number of servers in each station, for each stage
% 
%  Output:
%  ode_h:        handler of the ODE system
%  q_indices:    indices of each job class and station, in the state vector
%  ode_jumps_h:  handler of the jumps in the ODE system
%  ode_rates_h:  handler of the transition rates in the ODE system
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
