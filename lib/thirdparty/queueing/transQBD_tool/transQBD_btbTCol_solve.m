function pi=transQBD_btbTCol_solve(BC)
%
% this function computes the invariant vector \hat\pi_0\{0,l\}
% as desribed in Section 2.2.1. Reset to level zero.
%
% it computes the invariant vector of the matrix P = bTbT matrix 
% characterized by the block vector BC PLUS the Col vector matrix 
% (= matrix whose last block row differs from zero and equals BCR, 
% all other entries are zero). Here BCR contains only one non-zero 
% column, which is not needed to compute this invariant vector.

bl=size(BC,2);
k=size(BC,1)/bl;

for i=2:k
    X{i}=BC((i-1)*bl+1:i*bl,:);
end
for i=2:k
    X{i}=X{i}*(eye(bl)-BC(1:bl,:))^(-1);
    for j=i+1:k
        X{j}=X{j}+X{i}*BC((j-i)*bl+1:(j-i+1)*bl,:);
    end
end

X1_hlp = ones(bl,1)-BC(1:bl,:)*ones(bl,1);
for l = 1:bl
    X{1} = BC(1:bl,:) + kron([zeros(1,l-1) 1 zeros(1,bl-l)], X1_hlp);
    pi(l,(k-1)*bl+1:k*bl)=transQBD_stat(X{1});
    for i=2:k
        pi(l,(k-i)*bl+1:(k-i+1)*bl)=pi(l,(k-1)*bl+1:k*bl)*X{i};
    end 
end
