function EM = moments(pd,P,k,d)
% Compute moments for stationary distribution pd on the grid P
% imput:   - pd (approx. stationary distribution)
%          - P (approximating grid)
%          - k (routine computes up to the k-th moment for each coordinate)
%          - d (SRBM dimension)

% output   - EM (approx. moments)
%          - EM(i,j) approximates i-th moment on j-th coordinate

for i=1:k
    for j=1:d
        EM(i,j) = (P(:,j).^i)'*pd;
    end
end