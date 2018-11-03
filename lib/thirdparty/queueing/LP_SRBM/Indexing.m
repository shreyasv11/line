function [I N] = Indexing(d,m)
% Computing the number of elements on the basis
A(d,m+1) = factorial(m+d)/(factorial(d)*factorial(m));
A(d,1) = 1;
for i=m-1:-1:1
    A(d,i+1) = A(d,i+2)*(i+1)/(d+i+1);  
end
N = A(d,:);
for i=d-1:-1:1
    A(i,1)=1;
    for k = 1:m
        A(i,k+1) = A(i+1,k+1)*(i+1)/(i+1+k);
    end;    
end

% Computing indexes
for i=1:A(d,m+1)
    for j=d:-1:1
        K(j)=0;
        aux = 0;
        for h=j+1:d
            if K(h) >0
                aux = aux + A(h,K(h));
            end    
        end    
        if i - aux > A(j,1)      
            for k=2:m+1
                if i - aux  <=  A(j,k)
                    K(j)=k-1;
                    break;
                end
            end                
        end
    end
    
% Assigning indexes  | last index is the power of the function
    I(i,d+1) = K(d);
    for j=1:d-1
        I(i,j) = K(d+1-j)-K(d-j);
    end    
    I(i,d) = K(1);
end    
