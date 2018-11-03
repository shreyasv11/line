function vecout=transQBD_btbT_vec_multiply(vec,A,blrA)
%
% this function multiplies the vector vec with the bTbT matrix
% characterized by the block column A (blocks need not to be square)
% the optional parameter blrA gives the number of rows per block
% if absent square blocks are assumed

if (nargin < 3)
    blrA=size(A,2);
end

k=size(A,1)/blrA;

for i=1:k
    vecout((i-1)*size(A,2)+1:i*size(A,2))=vec((i-1)*blrA+1:end)*A(1:(k-i+1)*blrA,:);
end    