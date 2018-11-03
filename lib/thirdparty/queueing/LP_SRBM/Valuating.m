function V = Valuating(I,B,P,d);
% Valuates BAR interior term for each pair grid point- basis function
V(size(P,1),size(I,1))=0;
for i=1:size(I,1)
    v1= find(B(i,:,1));
    for j=v1
        v2 = find(I(j,1:d));
        I2 = I(j,v2);
        P2 = P(:,v2);
        aux= ones(size(P,1),length(v2));        
        for k=1:length(v2)
            aux(:,k) =P2(:,k).^I2(k);
        end
        if length(v2)==0
            V(:,i)= V(:,i) + B(i,j,1);;
        elseif length(v2)==1
            V(:,i)= V(:,i) + aux.*B(i,j,1);
        else
            V(:,i)= V(:,i) + (prod(aux')').*B(i,j,1);
        end
    end
end