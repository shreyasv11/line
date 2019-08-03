function XN = xpblow( L,N )
sigmaN=sum(L.^N)/sum(L.^(N-1));
XN=N/(sum(L)+sigmaN*(N-1));
end
