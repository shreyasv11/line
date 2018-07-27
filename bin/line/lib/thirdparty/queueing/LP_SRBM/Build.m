function [f A b Aeq beq lb n] = Build(V,D,P,d,K);
% Construct the linear programming formulation for SRBM. Generates
% parameters used by matlab function linprog.
% input :   - V (interior BAR value for each pair grid point-approximating
%             function)
%           - D (boundary BAR value for each triple gird
%             point-approximating function-dimension)
%           - d (SRBM dimension)
%           - K (tightness imposing bounds)

% output :  - f (objective function vector for linprog routine)
%           - A (lhs matrix for <= constraints for linprog routine)
%           - b (rhs vector for <= constraints for linprog routine)
%           - Aeq (lhs matrix for = constraints for linprog routine)
%           - beq (rhs vector for = constraints for linprog routine)
%           - lb (lower bounds for variables for linprog routine)
%           - n ( auxiliary dimension vector, used to read solution)

n(1)=0;
n(2)=size(P,1);
% BAR Constraints
A = V';
for k=1:d
    v1 = find(P(:,k)==0);
    n(k+2) = n(k+1) + length(v1);
    A = [A D(v1,:,k)'];
end
A = [A ; -A];
v3 = size(A,2)+1;
A(:,v3) = -1;

%Probability measure Constraint 
    vj = ones(1,n(2));
    vh = zeros(1,size(A,2)-n(2));    
    Aeq = [vj vh];
    beq = 1;

%Finite boundary measure Contraints
for k=2:d+1
    vi = zeros(1,n(k));
    vj = ones(1,n(k+1)-n(k));
    vh = zeros(1,size(A,2)-n(k+1));    
    A = [ A ; [vi vj vh]];
end

% Tightness Contraints
v4 = ones(d,1);
v5 = (P*v4)';
v6 = zeros(1,size(A,2)-length(v5));
A = [ A ; [v5 v6]];

for k=1:d
    vi = find(P(:,k)==0);    
    vj = zeros(1,n(k+1));
    vh = v5(vi);
    vk = zeros(1,size(A,2)-n(k+2));    
    A = [ A ; [vj vh vk]];
end

% Nonnegativity Contraints
lb = zeros(size(A,2),1);

% Value of vector C in linear program
f = zeros(size(A,2),1);
f(n(d+2)+1) = 1;

% Value of vector B in linear program
b = zeros(size(A,1),1);
b(2*size(V,2)+1:size(A,1))=K;
