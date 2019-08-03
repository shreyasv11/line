function [XN]=xzaba(L,N,Z)
    gamma=0;    
    Ltot=sum(L);
    LM=max(L);
    XN=min([1/LM N/(Ltot+Z)]);
end