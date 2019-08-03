function [XN]=xzabalow(L,N,Z)
    Ltot=sum(L);
    LM=max(L);
    XN=N/(Z+Ltot*N);
%    XN=1/Ltot;
end