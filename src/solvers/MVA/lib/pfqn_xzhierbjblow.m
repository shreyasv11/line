function [XN,gamma] = xzhierbjblow(L,N,Z,i)
[M,R]=size(L);
L=L(:);
N=N(:)';
singleonly = 1;
gamma = 0; %do not change
if N==0
    XN=0;
    return;
end


LM = max(L);
Ltot = sum(L);

if i==0
    XN=0;
else
    [xz,gamma]=xzhierbjblow(L,N-1,Z,i-1); 
    XN=N/(Z+Ltot+LM*(N-1-Z*xz));
end
end

