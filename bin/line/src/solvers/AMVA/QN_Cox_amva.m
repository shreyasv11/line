%  AMVAQD implements the QD-AMVA method proposed in the paper
%  "QD-AMVA: Evaluating Systems with Queue-Dependent Service
%  Requirements", by G. Casale, J. F. Perez, and W. Wang, accepted
%  to IFIP Performance 2015.
% 
%  Parameters:
%  L:    MxR double array with the mean service demand of class-r users in
%        station i, for r in {1,..,R} and i in {1,...,M}
%  N:    1xR integer array with the number of users of each class
%  S:    number of servers in node i (-1 if infinite)
%  SCV:  SCV(i,k) is the squared coefficient of variation of class k at
%        node i
%  ga:   Mx1 handle array with the handles of the gamma functions that
%        corresponds to each station
%  be:   MxR handle array with the handles of the beta functions that
%        corresponds to each station and each user class
%  tol:  stopping criteria - maximum difference in queue length between two
%        consecutive iterations
% 
%  Copyright (c) 2015-2018, Imperial College London
%  All rights reserved.
%
