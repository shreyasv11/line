function X=xzgbup(L,N,Z)
M=length(L);
D=0;
for i=1:M
    if (L(i)~=max(L))
    D=D+(max(L)-L(i))*qzgbup(L,N-1,Z,i); 
    end
end
X=min([N/(Z+sum(L)+min(L)*(N-1-Z*xzabaup(L,N-1,Z))-D),1/max(L)]);

end