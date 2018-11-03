function B = Basis(I,G,M,R,N,d,m);
% Constructing BAR coefficients for each basis function
H = I;
l = size(I,1);
B(l,l,d+1)=0;
for i=2:N(m+1)
    ni = max(I(i,d+1)-1,0);
    n0 = max(I(i,d+1)-3,0);
    aux= 1;
    if I(i,d+1) > 2
        aux = N(n0+1)+1;
    end;    
    for j =aux:N(ni+1);
        B(i,j,1)= 0;
        aux1  = I(i,1:d)-H(j,1:d);            
        aux2  = find(aux1);
        aux3  = aux1(aux2);
        if (aux3 >=0) & (sum(aux3)==1) & (I(i,aux2)>0)
            B(i,j,1) = I(i,aux2)*M(aux2);
            if I(i,aux2)==1
              B(i,j,aux2+1) = R(aux2,aux2);  
            end    
            for k=1:d
                if (I(i,k)==0)
                    B(i,j,k+1) = I(i,aux2)*R(aux2,k);
                end
            end
        elseif (aux3 >=0) & (sum(aux3)==2)
            if (length(aux2) == 1) & (I(i,aux2)>1)
                B(i,j,1) = G(aux2,aux2)*(I(i,aux2)*(I(i,aux2)-1))/2;
            else
                if I(i,aux2)>0
                    B(i,j,1) = prod(I(i,aux2))*G(aux2(1),aux2(2));
                end
            end
        end
    end
end