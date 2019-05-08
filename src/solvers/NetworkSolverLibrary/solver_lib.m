function [QN,UN,RN,TN,CN,XN] = solver_lib(qn, options)
% [Q,U,R,T,C,X] = SOLVER_LIB(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

%% generate local state spaces
M = qn.nstations;
K = qn.nclasses;
N = qn.njobs';
rt = qn.rt;
V = qn.visits;

QN = zeros(M,K);
UN = zeros(M,K);
RN = zeros(M,K);
TN = zeros(M,K);
CN = zeros(1,K);
XN = zeros(1,K);

if M==2 && K==1 && qn.nclosedjobs == 0
    source_ist = qn.nodeToStation(qn.nodetype == NodeType.Source);
    queue_ist = qn.nodeToStation(qn.nodetype == NodeType.Queue);
    lambda = qn.rates(source_ist)*qn.visits{1}(queue_ist);
    mu = qn.rates(queue_ist);
    ca = sqrt(qn.scv(source_ist));
    cs = sqrt(qn.scv(queue_ist));
    method = options.method;
    if strcmpi(method,'default')
        if ca == 1 && cs == 1
            method = 'mm1';
        elseif ca == 1
            method = 'mg1';
        elseif cs == 1
            method = 'gm1';
        else % gg1
            method = 'gig1.klb';
        end        
    end
    switch method
        case 'mm1'
            R=qsys_mm1(lambda,mu);
        case {'mg1', 'mgi1'}  % verified
            R=qsys_mg1(lambda,mu,cs);
        case {'gig1', 'gig1.kingman'}  % verified
            R=qsys_gig1_ubnd_kingman(lambda,mu,ca,cs);
        case 'gig1.heyman'
            R=qsys_gig1_approx_heyman(lambda,mu,ca,cs);
        case 'gig1.allen'
            R=qsys_gig1_approx_allencunneen(lambda,mu,ca,cs);
        case 'gig1.kobayashi'
            R=qsys_gig1_approx_kobayashi(lambda,mu,ca,cs);
        case 'gig1.klb'
            R=qsys_gig1_approx_klb(lambda,mu,ca,cs);
        case 'gig1.marchal' % verified
            R=qsys_gig1_approx_marchal(lambda,mu,ca,cs);
        case {'gm1', 'gim1'}
            % sigma = Load at arrival instants (Laplace transform of the inter-arrival times)
            LA = @(s) qn.lst{source_ist,1}(s);
            mu = qn.rates(queue_ist);
            sigma = fzero(@(x) LA(mu-mu*x)-x,0.5);
            R = qsys_gm1(sigma,mu);
        otherwise
            error('Line:UnsupportedMethod','Unsupported method for a model with 1 station and 1 class.');
    end
    RN(queue_ist,1) = R *qn.visits{1}(queue_ist);
    CN(queue_ist,1) = RN(1,1);
    XN(queue_ist,1) = lambda;
    UN(queue_ist,1) = lambda/mu;
    TN(source_ist,1) = lambda;
    TN(queue_ist,1) = lambda;
    QN(queue_ist,1) = XN(queue_ist,1) * RN(queue_ist,1);
else
    warning('This model is not supported yet. Returning with no result.');
end
end
