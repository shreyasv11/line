function AB=krons(A,B)
% Kronecker sum of matrices A and B
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
kron(eye(size(A)),B);
kron(A,eye(size(B)));
AB=kron(A,eye(size(B)))+kron(eye(size(A)),B);
end