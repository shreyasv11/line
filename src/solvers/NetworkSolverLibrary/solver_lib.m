function [Q,U,R,T,C,X] = solver_lib(qn, options)
% [Q,U,R,T,C,X] = SOLVER_LIB(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

%% generate local state spaces
M = qn.nstations;
K = qn.nclasses;
N = qn.njobs';
rt = qn.rt;
V = qn.visits;

Q = zeros(M,K);
U = zeros(M,K);
R = zeros(M,K);
T = zeros(M,K);
C = zeros(1,K);
X = zeros(1,K);

if M==2 && K==1 && qn.nclosedjobs == 0
    source_ist = qn.nodeToStation(qn.nodetype == NodeType.Source);
    queue_ist = qn.nodeToStation(qn.nodetype == NodeType.Queue);
    lambda = qn.rates(source_ist)*qn.visits{1}(queue_ist);
    mu = qn.rates(queue_ist);
    ca = sqrt(qn.scv(source_ist));
    cs = sqrt(qn.scv(queue_ist));
    switch options.method
        case 'mm1'
            W=qsys_mm1(lambda,mu);
        case {'mg1', 'mgi1'}  % verified
            W=qsys_mg1(lambda,mu,cs);
        case {'gig1', 'gig1.kingman'}  % verified
            W=qsys_gig1_ubnd_kingman(lambda,mu,ca,cs);
        case 'gig1.heyman'
            W=qsys_gig1_approx_heyman(lambda,mu,ca,cs);
        case 'gig1.allen'
            W=qsys_gig1_approx_allencunneen(lambda,mu,ca,cs);
        case 'gig1.kobayashi'
            W=qsys_gig1_approx_kobayashi(lambda,mu,ca,cs);
        case 'gig1.klb'
            W=qsys_gig1_approx_klb(lambda,mu,ca,cs);
        case 'gig1.marchal' % verified
            W=qsys_gig1_approx_marchal(lambda,mu,ca,cs);
        case {'gm1', 'gim1'}
            % sigma = Load at arrival instants (Laplace transform of the inter-arrival times)
            PH = qn.ph{source_ist};
            pie = map_pie(PH);
            A = PH{1};
            e = ones(length(pie),1);
            LA = @(s) pie*((s*eye(size(A))-A)\(-A))*e;
            mu = qn.rates(queue_ist);
            sigma = fzero(@(x) LA(mu-mu*x)-x,0.5);
            W = qsys_gm1(sigma,mu);
        case 'default'
            error('Line:UnsupportedMethod','This solver does not have a default solution method. Used the method option to choose a solution technique.');
        otherwise
            error('Line:UnsupportedMethod','Unsupported method for a model with 1 station and 1 class.');
    end
    R(queue_ist,1) = W *qn.visits{1}(queue_ist);
    C(queue_ist,1) = R(1,1);
    X(queue_ist,1) = lambda;
    U(queue_ist,1) = lambda/mu;
    T(source_ist,1) = lambda;
    T(queue_ist,1) = lambda;
    Q(queue_ist,1) = X(queue_ist,1) * R(queue_ist,1);
end
end
