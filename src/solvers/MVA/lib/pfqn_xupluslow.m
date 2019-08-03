function X=xupluslow(L,N)
M=length(L);
R=sum(L)+max(L)*(N-1);
for i=1:M
    if L(i)<max(L)
        Uplusi=xbjblow(Ladd(L,i),N-1)*L(i);
        R=R+(L(i)-max(L))*(Uplusi/(1-Uplusi));     
    end
end
X=N/R;

end