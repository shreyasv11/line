function X=xuplusup(L,N)
M=length(L);
R=sum(L)+max(L)*(N-1);
for i=1:M
    if L(i)>min(L)
        Uplusi=xbjbup(Ladd(L,i),N-1)*L(i);
        R=R+(L(i)-min(L))*(Uplusi/(1-Uplusi));     
    end
end
X=N/R;

end