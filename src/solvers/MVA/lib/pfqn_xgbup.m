function X=xgbup(L,N)
Xpb=xpbup(L,N-1);
R=sum(L)+max(L)*(N-1);
for i=1:length(L)
    if L(i)<max(L)
        Yi=L(i)*Xpb;
        R=R+(L(i)-max(L))*(Yi-Yi^N)/(1-Yi);
    end
end
X=N/R;
end