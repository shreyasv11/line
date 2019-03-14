function [Q,U,R,T,C,X] = solver_mva(ST,V,N,S,options,sched,refstat)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
[M,K]=size(ST);

if ~exist('sched','var')
    sched = cell(M,1);
    for i=1:M
        if isinf(S(i))
            sched{i} = SchedStrategy.INF;
        else
            sched{i} = SchedStrategy.PS; % default for non-inf servers is PS
        end
    end
end

extSET = find(cellfun(@(x) strcmpi(x,SchedStrategy.EXT),sched));
infSET = find(cellfun(@(x) strcmpi(x,SchedStrategy.INF),sched));
fcfsSET = find(cellfun(@(x) strcmpi(x,SchedStrategy.FCFS),sched));
if K==1
    pfSET = union(fcfsSET,union(find(cellfun(@(x) strcmpi(x,SchedStrategy.PS),sched)),find(cellfun(@(x) strcmpi(x,SchedStrategy.RAND),sched))));
else
    pfSET = union(find(cellfun(@(x) strcmpi(x,SchedStrategy.PS),sched)),find(cellfun(@(x) strcmpi(x,SchedStrategy.RAND),sched)));
end

U = zeros(M,K);
T = zeros(M,K);
C = zeros(1,K);
W = zeros(M,K);

ocl = [];
if any(isinf(N))
    ocl = find(isinf(N));
    for r=ocl % open classes
        X(r) = 1 ./ ST(refstat(r),r);
    end
end
rset = setdiff(1:K,find(N==0));

%% inner iteration

[X,Qpf,~] = pfqn_mva(ST(pfSET,:).*V(pfSET,:),N,ST(infSET,:).*V(infSET,:));
Q(pfSET,:) = Qpf;
Q(infSET,:) = repmat(X,numel(infSET),1) .* ST(infSET,:) .* V(infSET,:);

ccl = find(isfinite(N));
for r=ccl
    for k=1:M
        if isinf(S(k)) % infinite server
            W(k,r) = ST(k,r);
        else
            W(k,r) = Q(k,r) / (X(r) * V(k,r));
        end
    end
end

for r=ccl
    if sum(W(:,r)) == 0
        X(r) = 0;
    else
        if isinf(N(r))
            C(r) = V(:,r)'*W(:,r);
            % X(r) remains constant
        elseif N(r)==0
            X(r) = 0;
            C(r) = 0;
        else
            C(r) = V(:,r)'*W(:,r);
            X(r) = N(r) / C(r);
        end
    end
    
    for k=1:M
        Q(k,r) = X(r) * V(k,r) * W(k,r);
        T(k,r) = X(r) * V(k,r);
    end
end

for k=1:M
    for r=rset
        if isinf(S(k)) % infinite server
            U(k,r) = V(k,r)*ST(k,r)*X(r);
        else
            U(k,r) = V(k,r)*ST(k,r)*X(r)/S(k);
        end
    end
end

for k=1:M
    for r=1:K
        if V(k,r)*ST(k,r)>0
            switch sched{k}
                case {SchedStrategy.FCFS,SchedStrategy.PS}
                    if sum(U(k,:))>1
                        U(k,r) = min(1,sum(U(k,:))) * V(k,r)*ST(k,r)*X(r) / ((V(k,:).*ST(k,:))*X(:));
                    end
            end
        end
    end
end

R = Q./T;
X(~isfinite(X))=0;
U(~isfinite(U))=0;
Q(~isfinite(Q))=0;
R(~isfinite(R))=0;

X(N==0)=0;
U(:,N==0)=0;
Q(:,N==0)=0;
R(:,N==0)=0;
T(:,N==0)=0;
W(:,N==0)=0;

end
