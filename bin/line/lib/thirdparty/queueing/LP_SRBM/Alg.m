function [P pd vd u exitflag K] = Alg(n,d,m,G,M,R,mu);
%Main Algorithm routine
% imput:  - n (state space approximation parameter, number of
%           points on the approximating grid for each coordinate)
%         - m (functional space approximation parameter, degree of
%           polynomials on set of basis functions)
%         - d (dimension of the SRBM)
%         - G (Covariance matrix for SRBM)
%         - R (Reflextion matrix for SRBM)
%         - M (Drift vector for SRBM)
%         - mu (state space approximation parameter, vector that
%           determines the spacing on the approximating grid, check
%           ExpGrid.m)

% output - P (set of points on the approximating grid)
%        - pd (interior stationary distribution for SRBM)
%        - vd (boundary stationary distribution for SRBM)
%        - u (optimal objective function for approximating LP)
%        - exitflag (optimization status)
%        - K (bounds used for imposing tightness)


%Create the set of points
%P = DyaGrid(d,n);                              % Uniform grid -check DyaGrid to set parameters
P = ExpGrid(d,n,mu/4);                          % Exponential grid -check ExpGrid
%P = ExpRanGrid(d,n,mu./4);                     % Random Expgrid

%indexing set of basis functions
[I N] = Indexing(d,m);

%constructing BAR coefficients for basis functions  
B = Basis(I,G,M,R,N,d,m);

%Valuating interior and  boundary BAR terms
V = Valuating(I,B,P,d);
D = Daluating(I,B,P,d);

%Bounds for finiteness and tightness
K(1:2*d+1)= 100000;                              % using loose bounds (need to insert paper's bounds)

%Building LP(n,m)
[f A b Aeq beq lb z] = Build(V,D,P,d,K);

%Solving LP(n,m)
Options =optimset('MaxIter',1000,'display','iter');%,'TolX',1e-15,'TolX',1e-12);
[y u exitflag] = linprog(f,A,b,Aeq,beq,lb,Inf,0,Options);
pd(1:z(2))=y(1:z(2));                            % recovering interior solution
pd = pd';
for k=1:d
    vd(1:z(k+2)-z(k+1),k)=y(z(k+1)+1:z(k+2));    % recovering boundary solution
end