function XN=xbjbup(L,N)
XN = min([N/(sum(L)+mean(L)*(N-1)) 1/max(L)]);
end
