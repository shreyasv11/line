function Qgb=qgblow(L,N,i)
yi=N*L(i)/(sum(L)+max(L)*N);
Qgb=(yi- yi^(N+1))/(1-yi);
end