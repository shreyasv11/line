%  LQN defines a object for a Layered Queueing Network (LQN) model.
%  This object is defined as a list of processor objects.
%  More details on processors and their role in LQN models can be found
%  on the LINE documentation, available at http://line-solver.sourceforge.net
% 
%  Properties:
%  name:                 model name (string)
%  processors:           list of the processors that form part of this model
%  tasks:                list of tasks  - cell (task name, task ID, proc name, proc ID)
%  entries:              list of entries  - cell (entry name, task ID)
%  physical:             list of physical processors and workload sources
%                        cell - (proc name, proc ID, task name, task ID)
%  requesters:           list of activities that demand a service from an entry
%                        cell - (act name, task ID, proc name, target entry, procID)
%  providers:            list of activities/entries that provide services
%                        cell - (act name, entry name, task name, proc name, proc ID)
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc LayeredNetwork
%
%
