function [XN,QN,UN,CN,lGN] = pfqn_mva(L,N,Z,mi)
% [XN,QN,UN,CN] = pfqn_mva(L,N,Z,mi)
if isoctave
  warning off;
end
XN=[];QN=[];UN=[];CN=[];
% DEFAULTS
INFSERV=1;
lGN = 0;
%COMMAND-LINE OPTIONS
if nargin == 2
    INFSERV=0;
end

% CHECK PARAMETERS
[M,R]=size(L);
N=N(:)';

if nargin<4
    mi=ones(1,M);
end

if (~any(N))
    warning('ERROR: all populations empty (sum_r N_r =0)');
    return
end
NR=length(N);
if (R~=NR)
    error('ERROR: L and N have different number of classes');
    return;
end

% INITIALIZATION
XN=zeros(1,R);
QN=zeros(M,R);
CN=zeros(M,R);
if INFSERV==1
    Z=Z(:)';
else
    Z=zeros(1,R);
end

prods=zeros(1,R-1); % generate population indices
for w=1:R-1
    prods(1,w) = prod(ones(1,R-(w+1)+1)+N(1,w+1:R));
end

%%%%%% selezione della prima popolazione
firstnonempty=R;
while (N(firstnonempty)==0)
    firstnonempty = firstnonempty-1;
end
n=zeros(1,R); %pop corrente
n(1,firstnonempty)=1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

totpopolazioni=prod(N+1);
ctr=totpopolazioni;
Q=zeros(totpopolazioni,M);
currentpop=2;
n_1s=zeros(1,R);
%%%%%%%%%%%%%
doneupto=R+1; % popolazioni completate
%%%%%%%%%%%%%
while ctr % per ogni popolazione
    s=1;
    while s <= R
        pos_n_1s=0;
        if n(s)>0
            n(s) = n(s)-1;
            pos_n_1s= n(R);
            w=1;
            while w <= R-1
                pos_n_1s = pos_n_1s + n(w)*prods(w);
                w=w+1;
            end % while w <= R-1
            n(s) = n(s)+1;
        end % if
        CNtot=0;
        i=1;
        while i <= M
            Lis=L(i,s);
            CN(i,s)=Lis*(mi(i)+Q(1+pos_n_1s,i));
            CNtot=CNtot+CN(i,s);
            i=i+1;
        end % while i <= M
        XN(s)=n(s)/(Z(s)+CNtot);
        i=1;
        while i <= M
            QN(i,s)=XN(s)*CN(i,s);
            Q(currentpop,i)=Q(currentpop,i)+QN(i,s);
            i=i+1;
        end % while i <= M
        s=s+1;
    end % while s <= R
    s=R;
    while s>0 && (n(1,s)==N(s)) || s>firstnonempty
        s=s-1;
    end
    % now compute the normalizing constant
    last_nnz = max(find(n>0));
    if sum(n(1:last_nnz-1)) == sum(N(1:last_nnz-1)) & sum(n((last_nnz+1):R))==0
        logX = log(XN(last_nnz));
        if ~isempty(logX)
            lGN = lGN - logX;
        end
    end
    
    if s==0
        break;
    end
    n(s)=n(s)+1;
    s=s+1;
    while s<=R
        n(s)=0;
        s=s+1;
    end
    ctr=ctr-1;
    currentpop=currentpop+1;
end
for m=1:M
    for r=1:R
        UN(m,r)=XN(r)*L(m,r);
    end
end
end
