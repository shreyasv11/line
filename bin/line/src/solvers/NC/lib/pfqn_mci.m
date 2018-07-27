%  gmvamcint - normalizing constant estimation via Monte Carlo Integration
% 
%  Syntax:
%  [lG,lZ] = gmvamcint(D,N,Z,I,Iest)
%  Input:
%  D - demands (queues x classes)
%  N - populations (1 x classes)
%  Z - think times (1 x classes)
%  I - samples
% 
%  Output:
%  lG - estimate of logG
%  lZ - individual random samples
% 
%  Note: if the script returns a floating point range exception,
%  double(log(mean(exp(sym(lZ))))) provides a better estimate of lG, but it
%  is very time consuming due to the symbolic operations.
% 
%  Implementation: Giuliano Casale (g.casale@imperial.ac.uk), 16-Aug-2013
%
