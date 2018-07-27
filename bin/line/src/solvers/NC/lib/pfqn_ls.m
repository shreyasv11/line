%  PFQN_MCI Approximate solution of closed product-form queueing networks
%  by logistic sampling
% 
%  [Gn,lGn]=pfqn_ls(L,N,Z,I)
%  Input:
%  L : MxR demand matrix. L(i,r) is the demand of class-r at queue i
%  N : 1xR population vector. N(r) is the number of jobs in class r
%  Z : 1xR think time vector. Z(r) is the total think time of class r
%  I : number of samples (default: 1e5)
% 
%  Output:
%  Gn : estimated normalizing constat
% 
%  Reference:
%  G. Casale. Accelerating performance inference over closed systems by
%  asymptotic methods. ACM SIGMETRICS 2017.
%  Available at: http://dl.acm.org/citation.cfm?id=3084445
%
