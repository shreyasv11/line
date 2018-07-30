%  CQNCOX defines an object that represents a Closed Multi-Class Queueing
%  Network with Class Switching and Cox service times.
%  More details on this type of queueing networks can be found
%  on the LINE documentation, available at http://line-solver.sf.net
% 
%  Properties:
%  nstations:    number of stations (int)
%  nclasses:     number of classes (int)
%  N:            total population (int)
%  S:            number of servers per station (Mx1 int)
%  mu:           service rate in each service phase, for each job class in each station
%                (MxK cell with n_{i,k}x1 double entries)
%  phi:          probability of service completion in each service phase,
%                for each job class in each station
%                (MxK cell with n_{i,k}x1 double entries)
%  sched:        scheduling policy in each station
%                (Kx1 cell with string entries)
%  P:            transition matrix with class switching
%                (MKxMK matrix with double entries), indexed first by station, then by class
%  NK:           initial distribution of jobs in classes (Kx1 int)
%  C:            number of chains (int)
%  chains:       binary CxK matrix where 1 in entry (i,j) indicates that class
%                j belongs to chain i. Column sum must be 1. (CxK int)
%  refstat:      index of the reference node for each request class (Kx1 int)
%  bufsz:        (Mx1) matrix - entry i is the buffer size of station i
%  bufsz_class:  (MxK) matrix - entry (i,j) is the buffer size of station i
%                 for class j
%  stationnames:    name of each node
%                (Mx1 cell with string entries) - optional
%  classnames:   name of each job class
%                (Kx1 cell with string entries) - optional
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc QNCox
%
%
