function R=transQBD_formR(E0,E1,E2,F0,F1,F2,k)
%
% this function computes R block by block starting with R1, R2, ..., Rk
% each time it needs to solve a sylvester matrix equation unless E0=0.

m=size(E1,2);
if (sum(sum(E0)) == 0) % this case corresponds to having p=1
    Rs{1}=zeros(m,m);
else    
    Ahat=E1;
    A=E1;
    B=E0;
    C=E2;
    while (sum(sum(B)) > 10^(-50))
        Atemp=(eye(m)-A)^(-1);
        Ctemp=Atemp*C;
        BCtemp=B*Ctemp;
        Ahat=Ahat+BCtemp;
        Btemp=Atemp*B;
        A=A+B*Ctemp+C*Btemp;
        B=B*Btemp;
        C=C*Ctemp;
    end
    G=(eye(m)-Ahat)^(-1)*E2;  
    Rs{1}=E0*(eye(m)-(E1+E0*G))^(-1);
end
E2pF2=E2+F2;
temp=zeros(m,m);
for i=2:k
    if (sum(sum(E0)) > 0) % p is not 1 
        A=Rs{1};
        B=E2;
        C=E1+Rs{1}*E2-eye(m);
    end    
    %D=(i==2)*F0+Rs{i-1}*(F1+Rs{1}*F2); 
    D=(i==2)*F0+Rs{i-1}*F1; 
    temp=temp+(i>2)*Rs{1}*Rs{i-1}+Rs{i-1}*Rs{1};
    D=D+temp*F2;
    temp=zeros(m,m);
    for j=2:i-1
        temp=temp+Rs{j}*Rs{i-j+1};
    end
    D=D+temp*E2;
    if (sum(sum(E0))>0)
        Rs{i}=transQBD_sylvest(B',A',C',-D')';
    else
        Rs{i}=D*(eye(m)-E1)^(-1);
    end
end
for i=1:k
  R((i-1)*m+1:i*m,1:m)=Rs{i};
end  
