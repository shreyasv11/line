%  QN_Cox_fluid_RT(myQN, y0, RTrange, options, completes) 
%  computes the response time distribution of the original classes in the 
%  closed multi-class queueing network A
% 
%  Parameters:
%  myQN:         QNCox object describing the network
%  y0:           stationary state of the QN obtained via a fluid analysis
%  RTrange:      percetiles of the response distribution requested (optional)
%  options:      options data structure
% 
%  Output:
%  RT:           cell array containing the passage time distributions
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
