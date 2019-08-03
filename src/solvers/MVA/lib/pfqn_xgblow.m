function X=xgblow(L,N)
M=length(L);
R=sum(L)+max(L)*(N-1);
for i=1:M
    if L(i)<max(L)
    R=R+(L(i)-max(L))*qgblow(L,N-1,i);     
    end
end
X=N/R;

end