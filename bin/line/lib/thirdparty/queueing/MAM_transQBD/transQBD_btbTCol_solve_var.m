function pi=transQBD_btbTCol_solve_var(T,R)
%
% this function computes the invariant vector \hat\pi_0\{r,l\}
% as desribed in Section 2.2.2. Reset to an arbitrary level r>0.
%
% it computes the invariant vector of the matrix
% [ T_1  0   0   0  C_1 ]
% [ T_2 T_1  0   0  C_2 ]
% [ T_3 T_2 T_1  0  C_3 ]
% [ T_4 T_3 T_2 T_1 C_4 ]
% [ R_1 R_2 R_3 R_4 C_5 ]
% where C_i contains only one non-zero column,
% which is not needed to compute this invariant vector.

bl=size(T,2);
k=size(T,1)/bl;
art=size(R,1);

for i=2:k+1
    X{i}=R(:,(k+1-i)*bl+1:(k+2-i)*bl);
end    

for i=2:k+1
    X{i}=X{i}*(eye(bl)-T(1:bl,:))^(-1);
    for j=i+1:k+1
        X{j}=X{j}+X{i}*T((j-i)*bl+1:(j-i+1)*bl,:);
    end
end

for j=1:art
    pi(j,k*bl+1:k*bl+art)=[zeros(1,j-1) 1 zeros(1,art-j)];
    for i=2:k+1
        pi(j,(k+1-i)*bl+1:(k+1-i+1)*bl)=X{i}(j,:);
    end 
end
