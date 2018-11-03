function C=transQBD_btbT_multiply(A,B)
%
% this function computes the product of two lower block triangular
% block toeplitz matrices, A and B contain the first block column.

k=size(A,1)/size(A,2);
bl=size(A,2);

Anew=zeros(size(A'));
for i=1:k
    Anew(1:bl,(k-i)*bl+1:(k-i+1)*bl)=A((i-1)*bl+1:i*bl,1:bl);
end    
% Anew is a block row vector instead of a block column

C=zeros(size(A));
if (sum(sum(B(2*bl+1:end,:)))>0)
    for i=1:k
        C((i-1)*bl+1:i*bl,1:bl)=Anew(:,(k-i)*bl+1:end)*B(1:i*bl,:);
    end
else % optimization if B has only 2 non-zero blocks
    C(1:bl,:)=Anew(:,(k-1)*bl+1:end)*B(1:bl,:);
    for i=2:k
        C((i-1)*bl+1:i*bl,1:bl)=Anew(:,(k-i)*bl+1:(k-i+2)*bl)*B(1:2*bl,:);
    end
end    