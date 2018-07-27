%  ACTIVITY defines activity objects, as part of a Layered Queueing Network (LQN) model.
%  More details on activities and their role in LQN models can be found
%  on the LINE documentation, available at http://line-solver.sf.net
% 
%  Properties:
%  name:                 activity name (string)
%  phase:                number of phases in the activity (integer, 1 or 2)
%  hostDemandMean:       mean demand posed by the activity on the processor (double)
%  boundToEntry:         name of the entry that calls this activity as its first activity
%  synchCallDests:       list of entries called synchronously (string array)
%  synchCallMeans:       list of the mean number of each synchronous call (integer array)
%  asynchCallDests:      list of entries called asynchronously (string array)
%  asynchCallMeans:      list of the mean number of each asynchronous call (integer array)
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc Activity
%
%
