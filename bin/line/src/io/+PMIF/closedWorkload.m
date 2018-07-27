%  CLOSEDWORKLOAD defines CLOSEDWORKLOAD objects, as in a Performance Model Interchange Format (PMIF) model. 
% 
%  Properties:
%  name:                 workload name (string)
%  numberJobs:           number of jobs/users belonging to this workload/class (integer)
%  thinkTime:            mean time spent in a delay node (double)
%  thinkDevice:          name of the delay node (double)
%  timeUnits:            time units in which the think time is measured (string - optional)
%  transits:             list of (dest,prob) tuples describing the routing
%                        after the visit to the think node. Each entry holds
%                        the name of the destination node (dest) and the
%                        probability (prob)
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc PMIF.closedWorkload
%
%
