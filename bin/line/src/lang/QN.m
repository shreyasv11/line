%  QN defines an object that represents a Multi-Class Queueing Network.
% 
%  Properties:
%  nstations:            number of stations (int)
%  nclasses:            number of classes (int)
%  ntotaljobs:            total population (int)
%  S:            number of servers per station (Mx1 int)
%  rates:        service rate for each job class in each station
%                (MxK matrix with double entries)  --OLD: (Kx1 cell with Mx1 int as entries)
%  sched:        scheduling policy in each station
%                (Kx1 cell with string entries)
%  schedparam:    scheduling policy parameter in each station if applicable
%                (MxK) matrix - entry (i,j) is the weight of class j at
%                station i
%  P:            transition matrix with class switching
%                (MKxMK matrix with double entries), indexed first by station, then by class
%  njobs:           initial distribution of jobs in classes (Kx1 int)
%  C:            number of chains (int)
%  chains:       binary CxK matrix where 1 in entry (i,j) indicates that class
%                j belongs to chain i. Column sum must be 1. (CxK int)
%  refstat:      index of the reference node for each request class (Kx1 int)
%  capacity:        (Mx1) matrix - entry i is the buffer size of station i
%  classcapacity:  (MxK) matrix - entry (i,j) is the buffer size of station i
%                 for class j
%  space:        (Mx1) cell array, i-th element is the state space of station i
%  stationnames: name of each node
%                 (Mx1 cell with string entries) - optional
%  classnames:   name of each job class
%                 (Kx1 cell with string entries) - optional
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc QN
%
%
