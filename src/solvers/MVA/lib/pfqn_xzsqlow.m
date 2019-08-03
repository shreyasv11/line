function [XN,gamma,SQRT]=xzsqlow(L,N,Z)
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
checkfeasibleQN(L,N,0,1);

gamma = 0; %do not change

LM=max(L);
Ltot=sum(L);
R1=Ltot+Z;

a1=(N-1)/(N)*Z*LM;
b1=R1+(N-1)*LM;
SQRT=sqrt(b1^2-4*a1*N);

XN = min([2*N/(b1+sqrt(b1^2-4*a1*N)) 1/LM]);

end