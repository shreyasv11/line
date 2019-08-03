function runtime = run(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end

if ~self.supports(self.model)
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the solver.');
end
Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    error('The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end
method = options.method;
if qn.nstations==2 && qn.nclasses==1 && qn.nclosedjobs == 0 % open single-class queueing system
    T0=tic;
    source_ist = qn.nodeToStation(qn.nodetype == NodeType.Source);
    queue_ist = qn.nodeToStation(qn.nodetype == NodeType.Queue);
    lambda = qn.rates(source_ist)*qn.visits{1}(queue_ist);
    k = qn.nservers(queue_ist);
    mu = qn.rates(queue_ist);
    ca = sqrt(qn.scv(source_ist));
    cs = sqrt(qn.scv(queue_ist));
    if strcmpi(method,'exact')
        if ca == 1 && cs == 1 && k==1
            method = 'mm1';
        elseif ca == 1 && cs == 1 && k>1
            method = 'mmk';
        elseif ca == 1 && k==1
            method = 'mg1';
        elseif cs == 1 && k==1
            method = 'gm1';
        else
            error('Line:MethodNotAvailable','MVA exact method unavailable for this model.');
        end
    end
    
    switch method
        case 'default'
            if k>1
                method = 'gigk';
            else
                method = 'gig1.klb';
            end
    end
    
    switch method
        case 'mm1'
            R = qsys_mm1(lambda,mu);
        case 'mmk'
            R = qsys_mmk(lambda,mu,k);
        case {'mg1', 'mgi1'}  % verified
            R = qsys_mg1(lambda,mu,cs);
        case {'gigk'}
            R = qsys_gigk_approx(lambda,mu,ca,cs,k);
        case {'gigk.kingman_approx'}
            R = qsys_gigk_approx_kingman(lambda,mu,ca,cs,k);
        case {'gig1', 'gig1.kingman'}  % verified
            R = qsys_gig1_ubnd_kingman(lambda,mu,ca,cs);
        case 'gig1.heyman'
            R = qsys_gig1_approx_heyman(lambda,mu,ca,cs);
        case 'gig1.allen'
            R = qsys_gig1_approx_allencunneen(lambda,mu,ca,cs);
        case 'gig1.kobayashi'
            R = qsys_gig1_approx_kobayashi(lambda,mu,ca,cs);
        case 'gig1.klb'
            R = qsys_gig1_approx_klb(lambda,mu,ca,cs);
            if strcmpi(options.method,'default')
                method = sprintf('default [%s]','gig1.klb');
            end
        case 'gig1.marchal' % verified
            R = qsys_gig1_approx_marchal(lambda,mu,ca,cs);
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
    UN(queue_ist,1) = lambda/mu/k;
    TN(source_ist,1) = lambda;
    TN(queue_ist,1) = lambda;
    QN(queue_ist,1) = XN(queue_ist,1) * RN(queue_ist,1);
    lG = 0;
    runtime=toc(T0);
else % queueing network
    T0=tic;
    switch method
        case 'aba.upper'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                CN(1,1) = Z + N * sum(D);
                XN(1,1) = min( 1/Dmax, N / (Z + sum(D)));
                TN(:,1) = V .* XN(1,1);
                RN(:,1) = 1 ./ qn.rates * N;
                RN(qn.schedid == SchedStrategy.ID_INF,1) = 1 ./ qn.rates(qn.schedid == SchedStrategy.ID_INF,1);
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = 0;
            else
                QN = []; UN = [];
                RN = []; TN = [];
                CN = []; XN = [];
                lG = NaN;                
            end
            runtime=toc(T0);
        case 'aba.lower'
            if qn.nclasses==1 && qn.nclosedjobs >0 % closed single-class queueing network
                if any(qn.nservers(qn.schedid ~= SchedStrategy.ID_INF)>1)
                    error('Line:UnsupportedMethod','Unsupported method for a model with multi-server stations.');
                end
                V = qn.visits{1}(:);
                Z = sum(V(qn.schedid == SchedStrategy.ID_INF) ./ qn.rates(qn.schedid == SchedStrategy.ID_INF));
                D = V(qn.schedid ~= SchedStrategy.ID_INF) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                Dmax = max(D);
                N = qn.nclosedjobs;
                XN(1,1) = N / (Z + N*sum(D));
                CN(1,1) = Z + sum(D);
                TN(:,1) = V .* XN(1,1);
                RN(:,1) = 1 ./ qn.rates;
                QN(:,1) = TN(:,1) .* RN(:,1);
                UN(:,1) = TN(:,1) ./ qn.rates(qn.schedid ~= SchedStrategy.ID_INF);
                UN((qn.schedid == SchedStrategy.ID_INF),1) = QN((qn.schedid == SchedStrategy.ID_INF),1);
                lG = 0;
            else
                QN = []; UN = [];
                RN = []; TN = [];
                CN = []; XN = [];
                lG = NaN;                
            end
            runtime=toc(T0);
        otherwise
            [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_analysis(qn, options);
    end
end
    self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,method);
    self.result.Prob.logNormConstAggr = lG;
end

