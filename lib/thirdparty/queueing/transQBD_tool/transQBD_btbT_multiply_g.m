function C=transQBD_btbT_multiply_g(A,B)
%
% this function computes the product of two lower block triangular
% block toeplitz matrices, A and B contain the first block column.
% The blocks of A are not necessarily square 

blcA=size(A,2); % number of columns that the blocks of A have
k=size(B,1)/blcA; % number of blocks
blrA=size(A,1)/k;

Anew=zeros(blrA,blcA*k);
for i=1:k
    Anew(1:blrA,(k-i)*blcA+1:(k-i+1)*blcA)=A((i-1)*blrA+1:i*blrA,1:blcA);
end    
% Anew is a block row vector instead of a block column

C=zeros(size(A,1),size(B,2));
if ( sum(sum(B(2*blcA+1:end,:)))>0 && sum(sum(A(2*blrA+1:end,:)))>0 )
    for i=1:k
        C((i-1)*blrA+1:i*blrA,1:size(B,2))=Anew(:,(k-i)*blcA+1:end)*B(1:i*blcA,:);
    end
else 
    if (sum(sum(B(2*blcA+1:end,:)))==0)
        C(1:blrA,1:size(B,2))=Anew(:,(k-1)*blcA+1:end)*B(1:blcA,:);
        for i=2:k
            C((i-1)*blrA+1:i*blrA,1:size(B,2))=Anew(:,(k-i)*blcA+1:(k-i+2)*blcA)*B(1:2*blcA,:);
        end
    else
        C(1:blrA,1:size(B,2))=Anew(:,(k-1)*blcA+1:end)*B(1:blcA,:);
        for i=2:k
            C((i-1)*blrA+1:i*blrA,1:size(B,2))=Anew(:,(k-2)*blcA+1:end)*B((i-2)*blcA+1:i*blcA,:);
        end
    end
end    