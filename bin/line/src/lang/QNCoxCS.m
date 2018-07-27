%  CQNCOX defines an object that represents a Closed Multi-Class Queueing
%  Network with Class Switching and Cox service times.
%  More details on this type of queueing networks can be found
%  on the LINE documentation, available at http://line-solver.sf.net
% 
%  Properties:
%  nstations:    number of stations (int)
%  nclasses:     number of classes (int)
%  C:            number of chains (int)
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
%  chains:   binary CxK matrix where 1 in entry (c,j) indicates that class
%                j belongs to chain c. Column sum must be 1. (CxK int)
%  visits:  visits{c}(i,j) indicates the conditional
%                probability that a job at node i in chain c is of class j
%  refstat:     index of the reference node for each request class (Kx1 int)
%  stationnames:    name of each node
%                (Mx1 cell with string entries) - optional
%  classnames:   name of each job class
%                (Kx1 cell with string entries) - optional
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
