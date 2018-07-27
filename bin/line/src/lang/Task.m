%  TASK defines task objects, as part of a Layered Queueing Network (LQN) model.
%  More details on tasks and their role in LQN models can be found
%  on the LINE documentation, available at http://line-solver.sf.net
% 
%  Properties:
%  name:                 task name (string)
%  multiplicity:         task multiplicity (integer)
%  scheduling:           scheduling policy (string)
%  thinkTime:            mean think time of the workload associated with the task, if any (double)
%  entries:              array of entries associated to the    
%  activities:           activities executed by the task
%  initActID:            index of the initial activity (integer)
%  precedences:          array of the precedences among the activities
%  replyEntry:           entry called when the task is called
%  actGraph:             mxm matrix representing the activity graph
%  actNames:             names of the task activities (mx1 cell)
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc Task
%
%
