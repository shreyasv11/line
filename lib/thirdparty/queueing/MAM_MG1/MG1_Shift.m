function [hatA,drift]=MG1_Shift(A)
% this function performs the shift operation for the MG1 case
% input: A = [A0 A1 A2 ... A_maxd]

m=size(A,1);
maxd=size(A,2)/m-1;
sumA=A(:,maxd*m+1:end);
beta=sum(sumA,2);
% beta = (A_maxd)e + (A_maxd + A_maxd-1)e + ... + (Amaxd+...+A1)e
for i=maxd-1:-1:1
    sumA=sumA+A(:,i*m+1:(i+1)*m);
    beta=beta+sum(sumA,2);
end
sumA=sumA+A(:,1:m);
theta=stat(sumA);
drift=theta*beta;

A(:,m+1:2*m)=A(:,m+1:2*m)-eye(m);

% if drift < 1 : shift to zero, otherwise to infinity
hatA=zeros(m,m*(maxd+1));
if (drift < 1)
    colhatA=zeros(m,maxd+1);
    colhatA(:,1)=sum(A(:,1:m),2); % colhatA(:,1) = (A0)e
    for i=1:maxd
        colhatA(:,i+1)=colhatA(:,i)+sum(A(:,i*m+1:(i+1)*m),2); 
        % colhatA(:,i+1) = (A0+A1+...+Ai)e
    end 
    hatA=A-kron(colhatA,ones(1,m)/m); % hatAi = Ai - (A0+A1+...+Ai)e*uT
else
    rowhatA=zeros(1,m*(maxd+1));
    rowhatA(1,maxd*i:end)=theta*A(:,maxd*i:end);
    for i=maxd-1:-1:0
        rowhatA(1,i*m+1:(i+1)*m)=rowhatA(1,(i+1)*m+1:(i+2)*m)+...
            theta*A(:,i*m+1:(i+1)*m); % rowhatAi = theta(Amaxd+...+Ai)
    end
    hatA=A-ones(m,1)*rowhatA;
end    
    
hatA(:,m+1:2*m)=hatA(:,m+1:2*m)+eye(m);
