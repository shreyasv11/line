%  PFQN_LE Asymptotic solution of closed product-form queueing networks by
%  logistic expansion
% 
%  [Gn,lGn]=pfqn_le(L,N,Z)
%  Input:
%  L : MxR demand matrix. L(i,r) is the demand of class-r at queue i
%  N : 1xR population vector. N(r) is the number of jobs in class r
%  Z : 1xR think time vector. Z(r) is the total think time of class r
% 
%  Output:
%  Gn : estimated normalizing constat
%  lGn: logarithm of Gn. If Gn exceeds the floating-point range, only lGn
%       will be correctly estimated.
% 
%  Reference:
%  G. Casale. Accelerating performance inference over closed systems by
%  asymptotic methods. ACM SIGMETRICS 2017.
%  Availble at: http://dl.acm.org/citation.cfm?id=3084445
%
