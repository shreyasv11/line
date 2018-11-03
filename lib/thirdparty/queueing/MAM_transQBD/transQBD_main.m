function [Pi0,Pi] = transQBD_main(A_0,A_1,A_2,B_0,B_1,B_2,n,varargin)
% 
% Function: transQBD_main(A_0,A_1,A_2,B_0,B_1,B_2,n,varargin)
%
% Calculates the transient performance measures at the n-th MARKED time 
% epoch of a QBD for every possible initial configuration (level, state).
%
% 			     		---REMARK---
%
% To get the state at time n of a QBD characterized by the \bar A_i 
% and \bar B_i matrices, simply use 
%	A_i^m = \bar A_i and A_i^u = zeros(size(\bar A_i))
% and
%	B_i^m = \bar B_i and B_i^u = zeros(size(\bar B_i))
%
%			     		------------
%
%   Input:
%       A_i =[A_i^m; A_i^u]   B_i = [B_i^m; B_i^u]    (i=0,1,2)
%       n = marked time epoch of interest
%
%   Optional:       
%       r = maximum initial level
%       k = number of phases of the NBD distribution
%
%   Output:
%       Pi0{k}   = system state vector for initial configuration (0,k)
%       Pi{j}{k} = system state vector for initial configuration (j,k)

OptionNames=[
            'r';
            'k'];
OptionTypes=[
            'numeric';
            'numeric'];
OptionValues=[];

options=[];
for i=1:size(OptionNames,1)
    options.(deblank(OptionNames(i,:)))=[];
end
% Default settings
options.r = 100;
options.k = min(n-1,100);

warn_k = 0;
if options.k < n-1
    warn_k = 1;
end

% Parse Optional Parameters
options = transQBD_ParseOptPara(options,OptionNames,OptionTypes,OptionValues,varargin);

% Parameter of Bernoulli trial
k = options.k;
p = k/n;
m = size(A_1,1)/2;
l = size(B_1,1)/2;
km = k*m;

% Matrices A^{k,n} and B^{k,n}
A0 = [A_0(m+1:2*m,:)+(1-p)*A_0(1:m,:);p*A_0(1:m,:)];
A1 = [A_1(m+1:2*m,:)+(1-p)*A_1(1:m,:);p*A_1(1:m,:)];
A2 = [A_2(m+1:2*m,:)+(1-p)*A_2(1:m,:);p*A_2(1:m,:)];
B0 = [B_0(l+1:2*l,:)+(1-p)*B_0(1:l,:);p*B_0(1:l,:)];
B1 = [B_1(l+1:2*l,:)+(1-p)*B_1(1:l,:);p*B_1(1:l,:)];
B2 = [B_2(m+1:2*m,:)+(1-p)*B_2(1:m,:);p*B_2(1:m,:)];

% Reset to level 0
Rgr = transQBD_formR(A0(1:m,:),A1(1:m,:),A2(1:m,:),A0(m+1:2*m,:),A1(m+1:2*m,:),A2(m+1:2*m,:),k);
R00 = transQBD_btbT_multiply_g([B0;zeros((k-2)*l,m)], transQBD_btbT_invert([A1;zeros((k-2)*m,m)]+ ...
      transQBD_btbT_multiply(Rgr,[A2;zeros((k-2)*m,m)])));
M   = transQBD_btbT_invert([A1;zeros((k-2)*m,m)] + transQBD_btbT_multiply(Rgr,[A2; zeros((k-2)*m,m)]));

NT  = [B1; zeros((k-2)*l,l)] + transQBD_btbT_multiply_g(R00,[B2; zeros((k-2)*m,l)]);

pi0 = transQBD_btbTCol_solve(NT);
jv = 0;

dim=2^ceil(log2(2*k-1));
tempR=reshape(Rgr',m^2,k)';
tempR=fft(tempR,dim).';
tempR=reshape(tempR,m,m*dim).';

for ini=1:l
    normconst   = pi0(ini,:)*ones(k*l,1)+transQBD_btbT_vec_multiply(pi0(ini,:),...
                  transQBD_btbT_multiply_g(R00,transQBD_btbT_invert(Rgr)),l)*ones(km,1);
    pi0(ini,:)  = pi0(ini,:)/normconst;
    vecpi(ini,:)= transQBD_btbT_vec_multiply(pi0(ini,:),R00,l);
end
vecpir = zeros(l*20,km);
for ini=1:l
    vecpir(ini,:) = transQBD_btbT_vec_multiply(vecpi(ini,:),Rgr);
end
    
som = sum(pi0(1,:))+sum(sum(vecpi(1,:)))+sum(vecpir(1,:));
jv = 2;
while (som < 1-10^(-9))
    if mod(jv,20)==1
        vecpir(l*(jv-1)+1:l*(jv+19),:)=zeros(l*20,km);
    end
                
    vecout=zeros(l*dim,m);
    tempvec=zeros(l*m,k);
    for ini=1:l
        vec=vecpir((jv-2)*l+ini,:);
        tempvec((ini-1)*m+1:ini*m,:)=reshape(vec,m,k);
    end    
    tempvec=fliplr(tempvec)';
    tempvec=fft(tempvec,dim);
    tempvec=reshape(tempvec',m,dim*l)';  
    for loop_var=1:dim
        vecout((loop_var-1)*l+1:loop_var*l,1:m)=tempvec((loop_var-1)*l+1:loop_var*l,:)*tempR((loop_var-1)*m+1:loop_var*m,:);
    end
    vecout=reshape(vecout',m*l,dim)';
    vecout=real(ifft(vecout))';
    vecout2=zeros(l,m*dim);
    for ini=1:l
	   vecout2(ini,:)=reshape(vecout((ini-1)*m+1:ini*m,:),1,m*dim);
    end
    vecout2=reshape(vecout2(:,1:km)',m,k*l);
    vecout2=fliplr(vecout2);
    vecout2=reshape(vecout2,km,l);
    vecout2=fliplr(vecout2)';
    vecpir((jv-1)*l+1:jv*l,:) = vecout2;
        
    som = som + sum(vecpir((jv-1)*l+1,:));
    if norm(vecpir((jv-1)*l+1,:)-vecpir((jv-2)*l+1,:)) < 1e-16
        warning('Possible inexact results for level zero, sum(Pi) = %.12f',som);
        break
    end
    jv = jv+1;
end   
jv = jv-1;
vecpi      = vecpi(:,1:m);
vecpir     = reshape(vecpir(1:jv*l,1:m)',m*l,jv)';
for ini=1:l
    Pi0{ini}   = [[pi0(ini,1:l)';zeros(m-l,1)] vecpi(ini,:)' vecpir(:,(ini-1)*m+1:ini*m)'];
end
clear pi_0 vecpi vecpir;

if (options.r > 0)

    % Reset to level i
    Rinv    = transQBD_btbT_multiply(Rgr,transQBD_btbT_invert(Rgr));
    ident   = [zeros(m,km) eye(m)];
    RS_btbT = [eye(size(Rgr,2));zeros((k-1)*m,m)];
    RP_btbT = RS_btbT;
    RS      = [zeros(m,km) eye(m)];
    RP      = [zeros(m,km) eye(m)];
    RPh     = [zeros(m,km) eye(m)];

    i = 1;
    stop = 0;
    jv = 0;

    while(~stop)
        if i==1
            R0{i} = [transQBD_btbT_transpose(M) eye(m)];
        else
            for j=1:m
                R0{i}(j,:) = [transQBD_btbT_vec_multiply(transQBD_btbT_vec_multiply(R0{i-1}(j,1:km),...
                    [A2; zeros((k-2)*m,m)]),M) zeros(1,j-1) 1 zeros(1,m-j)];
            end
        end

        if i>1
            for j=1:m
                RS(j,1:km) = transQBD_btbT_vec_multiply(R0{i-1}(j,1:km),RS_btbT)+RS(j,1:km);
                RP(j,1:km) = transQBD_btbT_vec_multiply(R0{i-1}(j,1:km),RP_btbT)+RPh(j,1:km);
            end
            RS      = RS + ident;
            RPh     = RP;
            RP_btbT = transQBD_btbT_multiply(RP_btbT,Rgr);
            RS_btbT = RS_btbT+RP_btbT;
        end

        for j=1:m
            RP(j,1:km) = transQBD_btbT_vec_multiply(RP(j,1:km),Rinv);
            NR(j,:) = transQBD_btbT_vec_multiply(R0{i}(j,1:km),[B2;zeros((k-2)*m,l)],m);
        end

        norm_RS  = transQBD_btbT_multiply_g(R00,RS_btbT);
        norm_RP  = transQBD_btbT_multiply_g(R00,transQBD_btbT_multiply(RP_btbT,Rinv));

        sum_norm_RS(1:l,1) = norm_RS(1:l,:)*ones(m,1);
        sum_norm_RP(1:l,1) = norm_RP(1:l,:)*ones(m,1);

        for j=2:k
            sum_norm_RS((j-1)*l+1:j*l,1) = sum_norm_RS((j-2)*l+1:(j-1)*l,1)+norm_RS((j-1)*l+1:j*l,:)*ones(m,1);
            sum_norm_RP((j-1)*l+1:j*l,1) = sum_norm_RP((j-2)*l+1:(j-1)*l,1)+norm_RP((j-1)*l+1:j*l,:)*ones(m,1);
        end

        for j=1:m
            sum_norm_RS(k*l+j,1) = ([transQBD_btbT_vec_multiply(R0{i}(j,1:km),RS_btbT) zeros(1,m)]+RS(j,:))*...
                ones((k+1)*m,1);
            sum_norm_RP(k*l+j,1) = (transQBD_btbT_vec_multiply(R0{i}(j,1:km),transQBD_btbT_multiply(RP_btbT,Rinv))+...
                RP(j,1:km))*ones(km,1);
        end

        pi0 = transQBD_btbTCol_solve_var(NT,NR);
        pi0 = pi0./kron(ones(1,size(pi0,2)),sum(pi0')');
        normconst = ones(size(pi0,1),1)+pi0*(sum_norm_RS+sum_norm_RP);
        pi0 = pi0./kron(ones(1,size(pi0,2)),normconst);

        vecpi = zeros(i*m,(k+1)*m);
        for ini=1:m
            vecpi(ini,:) = [transQBD_btbT_vec_multiply(pi0(ini,1:k*l),R00,l) zeros(1,m)]+pi0(ini,k*l+1:k*l+m)*R0{i};
        end

        for j=2:i
            vecout=zeros(m*dim,m);
            tempvec=zeros(m*m,k);
            for ini=1:m
                vec=vecpi((j-2)*m+ini,1:k*m);
                tempvec((ini-1)*m+1:ini*m,:)=reshape(vec,m,k);
            end
            tempvec=fliplr(tempvec)';
            tempvec=fft(tempvec,dim);
            tempvec=reshape(tempvec',m,dim*m)';
            for loop_var=1:dim
                vecout((loop_var-1)*m+1:loop_var*m,1:m)=tempvec((loop_var-1)*m+1:loop_var*m,:)*tempR((loop_var-1)*m+1:loop_var*m,:);
            end
            vecout=reshape(vecout',m*m,dim)';
            vecout=real(ifft(vecout))';
            vecout2=zeros(m,m*dim);
            for ini=1:m
                vecout2(ini,1:m*dim)=reshape(vecout((ini-1)*m+1:ini*m,:),1,m*dim);
            end
            vecout2=reshape(vecout2(:,1:km)',m,km);
            vecout2=fliplr(vecout2);
            vecout2=reshape(vecout2,km,m);
            vecout2=fliplr(vecout2)';
            vecpi((j-1)*m+1:j*m,1:k*m) = vecout2;
            vecpi((j-1)*m+1:j*m,:) = [vecpi((j-1)*m+1:j*m,1:k*m) zeros(m,m)] + vecpi((j-2)*m+1:(j-1)*m,km+1:(k+1)*m)*R0{i-j+1};
        end

        if jv==0
            vecpir = zeros(m*20,km);
        else
            vecpir = zeros(m*(jv+20-mod(jv,20)),km);
        end

        for ini=1:m
            vecpir(ini,:) = transQBD_btbT_vec_multiply(vecpi((i-1)*m+ini,1:km),Rgr);
        end

        som = sum(pi0(1,:))+sum(vecpi(1,:))+sum(vecpir(1,:));
        for j=2:i
            som = som + sum(vecpi((j-1)*m+1,:));
        end

        jv = 2;
        while (som < 1-10^(-9))
            if mod(jv,20)==1
                vecpir(m*(jv-1)+1:m*(jv+19),:)=zeros(m*20,km);
            end

            vecout=zeros(m*dim,m);
            tempvec=zeros(m*m,k);
            for ini=1:m
                vec=vecpir((jv-2)*m+ini,:);
                tempvec((ini-1)*m+1:ini*m,:)=reshape(vec,m,k);
            end

            tempvec=fliplr(tempvec)';
            tempvec=fft(tempvec,dim);
            tempvec=reshape(tempvec',m,dim*m)';

            for loop_var=1:dim
                vecout((loop_var-1)*m+1:loop_var*m,1:m)=tempvec((loop_var-1)*m+1:loop_var*m,:)*tempR((loop_var-1)*m+1:loop_var*m,:);
            end
            vecout=reshape(vecout',m*m,dim)';
            vecout=real(ifft(vecout))';
            vecout2=zeros(m,m*dim);
            for ini=1:m
                vecout2(ini,1:m*dim)=reshape(vecout((ini-1)*m+1:ini*m,:),1,m*dim);
            end
            vecout2=reshape(vecout2(:,1:km)',m,km);
            vecout2=fliplr(vecout2);
            vecout2=reshape(vecout2,km,m);
            vecout2=fliplr(vecout2)';
            vecpir((jv-1)*m+1:jv*m,:) = vecout2;

            som = som + sum(vecpir((jv-1)*m+1,:));
            if norm(vecpir((jv-1)*m+1,:)-vecpir((jv-2)*m+1,:)) < 1e-16
                warning('Possible inexact results for level zero, sum(Pi) = %.12f',som);
                break
            end
            jv = jv+1;
        end

        jv = jv-1;
        % Original steady state probabilities
        c = ones(1,m) - (sum(reshape(vecpi(:,km+1:end),m,m*i),2)'+sum(pi0(:,k*l+1:end)));
        vecpi   = reshape(vecpi(:,1:m)',m*m,i)';
        vecpir  = reshape(vecpir(1:m*jv,1:m)',m*m,jv)';
        pi_0 = pi0(:,1:l)';

        for ini=1:m
            Pi{i}{ini} = [[pi_0(:,ini); zeros(m-l,1)] vecpi(:,(ini-1)*m+1:ini*m)' vecpir(:,(ini-1)*m+1:ini*m)']/c(1,ini);
        end

        clear pi_0 vecpi vecpir;

        if i>1
            for ini=1:m
                stopcrit(1,ini) = norm(Pi{i}{ini}(1,1)-Pi{i-1}{ini}(1,1));
            end

            if ((norm(stopcrit)) < 1e-14)
                stop = 1;
            end
            if (i == options.r)
                stop = 1;
                warning('Maximum level r = %d reached.', options.r);
            end
        end
        i=i+1;
    end
end    

if warn_k
    warning('Approximation used: k = %d.', options.k);
end
