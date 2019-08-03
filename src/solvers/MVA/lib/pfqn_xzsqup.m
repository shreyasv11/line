function [XN,gamma,SQRT]=xzsqup(L,N,Z)
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
checkfeasibleQN(L,N,0,1);

gamma = 0; %SBAGLIATO CAMBIARE

LM=max(L);
Ltot=sum(L);
R1=Ltot+Z;
La=mean(L);

a2=Z*La;
b2=R1+(N-1)*La;
SQRT=sqrt(b2^2-4*a2*N);

x=(-b2+sqrt(b2^2-4*a2*N))/(2*a2);

XN = min([N/(b2+a2*x) 1/LM]);

end