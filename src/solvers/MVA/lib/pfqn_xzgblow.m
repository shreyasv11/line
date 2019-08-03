function X=xzgblow(L,N,Z)
M=length(L);
R=Z+sum(L)+max(L)*(N-1);
for i=1:M
    R=R+(L(i)-max(L))*qzgblow(L,N-1,Z,i); 
end
X=N/R;

end