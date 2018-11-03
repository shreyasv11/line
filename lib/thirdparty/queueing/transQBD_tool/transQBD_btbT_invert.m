function B=transQBD_btbT_invert(A)
%
% this function computes the inverse of (I-A) with
% A a lower block triangular block toeplitz matrix
% A is given by its first block column

k=size(A,1)/size(A,2);
bl=size(A,2);

% we write B in an order to speed up the algorithm
A=-A;
A(1:bl,1:bl)=eye(bl)+A(1:bl,1:bl);
invA=inv(A(1:bl,1:bl));
A=A*invA;
Bold=zeros(size(A'));
Bold(1:bl,(k-1)*bl+1:k*bl)=invA;
for i=2:k
  Bold(:,(k-i)*bl+1:(k-i+1)*bl)=-Bold(:,(k-i+1)*bl+1:end)*A(bl+1:i*bl,:);
end
B=zeros(size(A));
for i=1:k
    B((i-1)*bl+1:i*bl,:)=Bold(:,(k-i)*bl+1:(k-i+1)*bl);
end    