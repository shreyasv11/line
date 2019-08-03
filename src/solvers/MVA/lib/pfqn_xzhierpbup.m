function [XN,gamma ] = xzhierpbup( L,N,Z,i )
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
gamma = 0; %do not change
if N==0
    XN=0;
    return;
end


La = mean(L);
LM = max(L);
Ltot = sum(L);
sigma = sum(L.^2)/Ltot;

if i==0
    XN=xzabaup(L,N,Z);
else
    [xz,gamma]=xzhierpbup(L,N-1,Z,i-1); 
    XN = min([N/(Z+Ltot+sigma*(N-1-Z*xz)) xzabaup(L,N,Z)]);
end
end
