function [XN,gamma ] = xzhierpblow( L,N,Z,i )
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
gamma = 0; %do not change


La = mean(L);
LM = max(L);
Ltot = sum(L);
sigmalow=(sum(L.^N)/sum(L.^(N-1)));
if isnan(sigmalow) | isinf(sigmalow)
   sigmalow=LM;
end

if i==0
    XN=0;%xzabalow(L,N,Z);
else
    [xz,gamma]=xzhierpblow(L,N-1,Z,i-1); 
    XN = N/(Z+Ltot+sigmalow*(N-1-Z*xz));
end
end
