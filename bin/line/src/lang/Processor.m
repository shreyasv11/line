%  PROCESSOR defines processor objects, as part of a Layered Queueing Network (LQN) model. 
%  More details on processors and their role in LQN models can be found 
%  on the LINE documentation, available at http://line-solver.sourceforge.net/
% 
%  Properties:
%  name:                 processor name (string)
%  ID:                   unique identifier of the processor (integer)
%  multiplicity:         processor multiplicity (integer)
%  scheduling:           scheduling policy (string)
%  quantum:              processor quantum (double)
%  speedFactor:          factor to modify the processor's speed (double) 
%  tasks:                list of the tasks deployed on this processor (string array)
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc Processor
%
%
