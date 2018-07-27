function R=GIM1_R(A,Algor,varargin)
%GIM1_R determines R matrix of a GI/M/1-Type Markov Chain  
%
%   R=GIM1_R(A,Algor) computes the minimal nonnegative solution to the 
%   matrix equation R = A0 + R A1 + R^2 A2 + R^3 A3 + ... + R^max A_max, 
%   where A = [A0 A1 A2 A3 ... A_max] has m rows and m*max columns and is
%   a nonnegative matrix, with (A0+A1+A2+...+A_max) irreducible and 
%   stochastic.
%
%   The parameter Algor determines the class of algorithms used to 
%   compute G. This is realized by computing the G matrix of the 
%   Ramaswami Dual of the Markov chain.
%
%   Four classes are supported: 
%
%       'FI' : Functional Iterations [Neuts]
%       'CR' : Cyclic Reduction [Bini, Meini]
%       'RR' : Ramaswami Reduction [Bini, Meini, Ramaswami]
%       'IS' : Invariant Subspace [Akar, Sohraby]
%
%   Optional Parameters:
%   
%       See MG1_FI, MG1_CR, MG1_RR and MG1_IS for the supported
%       optional parameters

m=size(A,1);
dega=size(A,2)/m-1;

% compute invariant vector of A=A0+A1+A2+...+Amax
sumA=A(:,dega*m+1:end);
for i=dega-1:-1:0
    sumA=sumA+A(:,i*m+1:(i+1)*m);
end
theta=stat(sumA);

% compute the Dual process
for i=0:dega
    A(:,i*m+1:(i+1)*m)=diag(theta.^(-1))*A(:,i*m+1:(i+1)*m)'*diag(theta);
end    

switch Algor
    case 'FI'
        G=MG1_FI(A,varargin{:});
    case 'CR'
        G=MG1_CR(A,varargin{:});
    case 'RR'
        G=MG1_RR(A,varargin{:});
    case 'IS'
        G=MG1_IS(A,varargin{:});
    otherwise
        error('MATLAB:GIM1_R:InvalidAlgor',...
            'Algorithm ''%s'' is not supported',Algor)
end

R=diag(theta.^(-1))*G'*diag(theta);