function B=transQBD_btbT_transpose(A)
%
% this function computes the transpose of A with
% A a lower block triangular block toeplitz matrix
% A is given by its first block column

k=size(A,1)/size(A,2);
bl=size(A,2);

B=zeros(bl,k*bl);
for j=1:k
    B(:,(j-1)*bl+1:j*bl) = A((k-j)*bl+1:(k-j+1)*bl,:);
end
