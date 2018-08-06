%  Q = QN_Cox_fluid(qn, options) computes the fixed point Q of the ODE
%  system that describes a Closed Multi-Class Queueing Network with Class Switching
%  and Cox processing times (QNCox) qn.
% 
%  Parameters:
%  qn:      CQN model to analyze
% 
%  Output:
%  QN:         expected number of jobs of each class in each station (fixed point)
%  ymean:  expected steady state vector
%  iters:      actual number of iterations
%  usesstiff:  indicator of whether stiff solvers were used or not
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
