function Qgb=qgbup(L,N,i)
sigma=sum(L.^2)/sum(L);
Yi=L(i)*min([1/max(L),N/(sum(L)+sigma*(N-1))]);
if Yi~=1
    Qgb=Yi/(1-Yi) - (Yi^(N+1))/(1-Yi);
else
    Qgb=N;
end
end