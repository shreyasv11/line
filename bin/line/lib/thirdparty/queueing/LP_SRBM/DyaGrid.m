function P = DyaGrid(d,n);
ncoord = 2^(2*n)+1;
npoints = (ncoord)^d;
for k=1:d
   aux = ncoord^(d-k);
   for j = 1:npoints;
       P(j,k) = rem(floor((j-1)/aux), ncoord);
   end    
end
P = P./(2^(n));
return
ncoord = n^2+1;
npoints = (ncoord)^d;
for k=1:d
    aux = ncoord^(d-k);
    for j = 1:npoints;
        P(j,k) = rem(floor((j-1)/aux), ncoord);
    end    
end
P = P./(n^2)*3.33;

for k=1:d
    for j = 1:npoints;
       if P(j,k)>3 
           P(j,k) = P(j,k) +(P(j,k)-3)*10;
       end    
    end    
end