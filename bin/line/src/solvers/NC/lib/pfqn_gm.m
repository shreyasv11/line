%  PFQN_GM Exact and approximate solution of closed product-form queueing 
%  networks by Grundmann-Moeller cubature rules
%  
%  [Gn,lGn]=pfqn_gm(L,N,Z,S)
%  Input:
%  L : MxR demand matrix. L(i,r) is the demand of class-r at queue i
%  N : 1xR population vector. N(r) is the number of jobs in class r
%  Z : 1xR think time vector. Z(r) is the total think time of class r
%  S : degree of the cubature rule. Exact if S=ceil((sum(N)-1)/2).
% 
%  Output:
%  Gn : estimated normalizing constat
%  lGn: logarithm of Gn. If Gn exceeds the floating-point range, only lGn
%       will be correctly estimated.
% 
%  Reference:
%  G. Casale. Accelerating performance inference over closed systems by 
%  asymptotic methods. ACM SIGMETRICS 2017.
%  Available at: http://dl.acm.org/citation.cfm?id=3084445
%
