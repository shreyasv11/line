%  PFQN_CA Exact solution of closed product-form queueing networks by the
%  convolution algorithm
% 
%  [Gn,lGn]=pfqn_ca(L,N,Z)
%  Input:
%  L : MxR demand matrix. L(i,r) is the demand of class-r at queue i
%  N : 1xR population vector. N(r) is the number of jobs in class r
%  Z : 1xR think time vector. Z(r) is the total think time of class r
% 
%  Output:
%  Gn : estimated normalizing constat
% 
%  References:
%  J. P. Buzen. Computational algorithms for closed queueing networks with
%  exponential servers. Comm. of the ACM, 16(9):527–531, 1973.
% 
%  H. Kobayashi, M. Reiser. Queueing Networks with Multiple Closed Chains:
%  Theory and Computational Algorithms, IBM J. Res. Dev., 19(3), 283--294,
%  1975.
%
