function XN=xpbup(L,N)
sigma2=sum(L.^2)/sum(L.^(2-1));
XN=min([N/(sum(L)+sigma2*(N-1)),1/max(L)]);
end
