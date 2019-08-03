function [XN,gamma,SQRT]=xzpsqup(L,N,Z)
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
checkfeasibleQN(L,N,0,1);

gamma = 0; %do not change

sigma = sum(L.^2)/sum(L);

LM=max(L);
Ltot=sum(L);
R1=Ltot+Z;

a2=Z*sigma;
b2=R1+(N-1)*sigma;
SQRT=sqrt(b2^2-4*a2*N);

XN = min([2*N/(b2+sqrt(b2^2-4*a2*N)) 1/LM]);

end