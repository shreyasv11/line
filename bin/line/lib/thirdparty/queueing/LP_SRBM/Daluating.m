 function D = Daluating(I,B,P,d);
% Valuates BAR boundary terms for each pair grid point- basis function
D(size(P,1),size(I,1),d)=0;
for i=1:size(I,1)
    for h=1:d
        v1= find(B(i,:,h+1));
        v3 = find(P(:,h)==0);
        for j=v1
            v2 = find(I(j,1:d));
            I2 = I(j,v2);           
            P2 = P(v3,v2);
            aux= ones(length(P(v3,1)),length(v2));
            for k=1:length(v2)
                aux(:,k) =P2(:,k).^I2(k);
            end
            if length(v2)==0
                D(v3,i,h)= D(v3,i,h) + B(i,j,h+1);
            elseif length(v2)==1
                D(v3,i,h)= D(v3,i,h) + aux.*B(i,j,h+1);
            else
                D(v3,i,h)= D(v3,i,h) + (prod(aux')').*B(i,j,h+1);
            end
        end
    end
end