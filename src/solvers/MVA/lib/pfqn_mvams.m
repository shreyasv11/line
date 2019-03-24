function [XN,QN,UN,CN,lGN]=pfqn_mvams(L,N,Z,mi,c)
% c(i) number of servers in station i
[M,R]=size(L); % get number of queues (M) and classes (R)
Ntot = sum(N(isfinite(N)));
mu = ones(M,Ntot);
if ~exist('c','var')
    c = ones(M,1);
end
if ~exist('mi','var')
    mi = ones(M,1);
end
for i=1:M
    mu(i,:) = min(1:Ntot,c(i)*ones(1,Ntot));
end
if max(c(isfinite(c))) == 1
    [XN,QN,UN,CN,lGN] = pfqn_mva(L,N,Z,mi);
else
    [XN,QN,UN,CN,lGN] = pfqn_mvald(L,N,Z,mu);
end
return
end
