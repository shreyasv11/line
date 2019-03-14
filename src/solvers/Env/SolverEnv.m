classdef SolverEnv < EnsembleSolver
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

    
    properties
        env; % user-supplied representation of each stage transition
        envMMAP; % MMAP representation of each stage transition
        holdTime; % holding times
        probEnv; % steady-state probability of the environment
        probOrig; % probability that a request originated from phase
    end
    
    methods
        function self = SolverEnv(models,env,solverFactory,options)
            self = self@EnsembleSolver(Ensemble(models),mfilename,options);
            self.env = env;
            for e=1:length(env)
                self.setSolver(solverFactory(models{e}),e);
            end
            
            for e=1:length(self.env)
                for h=1:length(self.env)
                    if ~isa(self.env{e,h},'PhaseType')
                        error('The distribution of the environment transition from stage %d to %d is not supported by the %s solver. Quitting.',e,h,self.getName);
                    end
                end
            end
            
            for e=1:length(self.ensemble)
                if ~self.solvers{e}.supports(self.ensemble{e})
                    error('Model in the environment stage %d is not supported by the %s solver. Quitting.',e,self.getName);
                end
            end
        end
        
        function bool = converged(self, it) % convergence test at iteration it
            bool = false;
            E = self.getNumberOfModels;
            if it>1
                mapes = zeros(1,E);
                for e=1:E
                    for i=1:size(self.results{it,e}.TranAvg.Q,1)
                        for j=1:size(self.results{it,e}.TranAvg.Q,2)                            
                            % error is calculated only on entry value (t=0)
                            mapes(e) = max(mapes(e), mape(self.results{it,e}.TranAvg.Q{i,j}(1,1), self.results{it-1,e}.TranAvg.Q{i,j}(1,1)));
                        end
                    end
                end                
                if max(mapes) < self.options.iter_tol
                    bool = true;
                end
                if self.options.verbose
                    fprintf(1,'Iteration %3d, max abs. perc. error: %f\n',it,max(mapes));
                end
            else
                if self.options.verbose
                    fprintf(1,'Iteration %3d, max abs. perc. error: %f\n',it,Inf);
                end                
            end
        end
        
        
        function init(self)
            options = self.options;
            
            if isfield(options,'seed')
                rand('seed',options.seed);
            end
            
            E = self.getNumberOfModels;
            Pemb = zeros(E);
            
            % analyse holding times
            envMMAP = cell(E);
            self.holdTime = {};
            for e=1:E
                for h=1:E
                    envMMAP{e,h} = self.env{e,h}.getRenewalProcess; % multiclass MMAP representation
                    for j = 1:E
                        if j == h
                            envMMAP{e,h}{2+j} = envMMAP{e,h}{2};
                        else
                            envMMAP{e,h}{2+j} = 0 * envMMAP{e,h}{2};
                        end
                    end
                end
                self.holdTime{e} = envMMAP{e,e};
                for h=setdiff(1:E,e)
                    self.holdTime{e}{1} = krons(self.holdTime{e}{1},envMMAP{e,h}{1});
                    for j = 2:(E+2)
                        self.holdTime{e}{j} = krons(self.holdTime{e}{j},envMMAP{e,h}{j});
                        completion_rates = self.holdTime{e}{j}*ones(length(self.holdTime{e}{j}),1);
                        self.holdTime{e}{j} = 0*self.holdTime{e}{j};
                        self.holdTime{e}{j}(:,1) = completion_rates;
                    end
                    self.holdTime{e} = mmap_normalize(self.holdTime{e});
                end
                count_lambda = mmap_count_lambda(self.holdTime{e}); % completiom rates for the different transitions
                Pemb(e,:) = count_lambda/sum(count_lambda);
            end
            self.envMMAP = envMMAP;
            
            %
            lambda = zeros(1,E);
            A = zeros(E); I=eye(E);
            for e=1:E
                lambda(e) = 1/map_mean(self.holdTime{e});
                for h=1:E
                    A(e,h) = -lambda(e)*(I(e,h)-Pemb(e,h));
                end
            end
            probEnv = ctmc_solve(A);
            self.probEnv = probEnv;
            self.probOrig = zeros(E);
            for e = 1:E
                for h = 1:E
                    self.probOrig(h,e) = probEnv(h) * lambda(h) * Pemb(h,e);
                end
                if probEnv(e) > 0
                    self.probOrig(:,e) = self.probOrig(:,e) / sum(self.probOrig(:,e));
                end
            end            
            
        end
        
        function pre(self, it)
            if it==1
                for e=self.list()
                    [QN,~,~,~] = self.getSolver(e).getAvg();
                    self.ensemble{e}.initFromMarginal(QN);
                end
            end
        end
        
        % solves model in stage e
        function [results_e, runtime] = analyze(self, it, e)
            results_e = struct();
            results_e.('TranAvg') = [];
            T0 = tic;
            runtime = toc(T0);
            %% initialize
            [Qt,Ut,Tt] = self.ensemble{e}.getTranHandles;                        
            %[results_e.Avg.Q, results_e.Avg.U, results_e.Avg.R, results_e.Avg.T] = self.solvers{e}.getAvg();            
            [results_e.TranAvg.Q, results_e.TranAvg.U, results_e.TranAvg.T] = self.solvers{e}.getTranAvg(Qt,Ut,Tt);           
        end
        
        function post(self, it)
            E = self.getNumberOfModels;
            for e=1:E                
                QExit{e}=[];
                for i=1:size(self.results{it,e}.TranAvg.Q,1)
                    for r=1:size(self.results{it,e}.TranAvg.Q,2)
                        w{e} = [0, map_cdf(self.holdTime{e}, self.results{it,e}.TranAvg.Q{i,r}(2:end,2)) - map_cdf(self.holdTime{e}, self.results{it,e}.TranAvg.Q{i,r}(1:end-1,2))]';
                        QExit{e}(i,r) = self.results{it,e}.TranAvg.Q{i,r}(:,1)'*w{e}/sum(w{e});
                    end
                end
                for h = 1:E
                    QE{e,h} = zeros(size(self.results{it,e}.TranAvg.Q));
                    for i=1:size(self.results{it,e}.TranAvg.Q,1)
                        for r=1:size(self.results{it,e}.TranAvg.Q,2)
                            w{e,h} = [0, map_cdf(self.envMMAP{e,h}, self.results{it,e}.TranAvg.Q{i,r}(2:end,2)) - map_cdf(self.envMMAP{e,h}, self.results{it,e}.TranAvg.Q{i,r}(1:end-1,2))]';
                            if ~isnan(w{e,h})
                                QE{e,h}(i,r) = self.results{it,e}.TranAvg.Q{i,r}(:,1)'*w{e,h}/sum(w{e,h});
                            else
                                QE{e,h}(i,r) = 0;
                            end
                        end
                    end
                end
            end
            
            Q0 = cell(1,E); % average entry queue-length
            for e = 1:E
                Q0{e} = zeros(size(QE{e}));
                for h=1:E
                    Q0{e} = Q0{e} + self.probOrig(h,e) * QE{h,e};
                end
                self.solvers{e}.reset();                
                self.ensemble{e}.initFromMarginal(Q0{e});
            end
        end
        
        function finish(self)
            it = size(self.results,1); % use last iteration
            E = self.getNumberOfModels;
            for e=1:E                
                QExit{e}=[];
                UExit{e}=[];
                TExit{e}=[];
                for i=1:size(self.results{it,e}.TranAvg.Q,1)
                    for r=1:size(self.results{it,e}.TranAvg.Q,2)
                        w{e} = [0, map_cdf(self.holdTime{e}, self.results{it,e}.TranAvg.Q{i,r}(2:end,2)) - map_cdf(self.holdTime{e}, self.results{it,e}.TranAvg.Q{i,r}(1:end-1,2))]';
                        QExit{e}(i,r) = self.results{it,e}.TranAvg.Q{i,r}(:,1)'*w{e}/sum(w{e});
                        UExit{e}(i,r) = self.results{it,e}.TranAvg.U{i,r}(:,1)'*w{e}/sum(w{e});
                        TExit{e}(i,r) = self.results{it,e}.TranAvg.T{i,r}(:,1)'*w{e}/sum(w{e});
                    end
                end
%                 for h = 1:E
%                     QE{e,h} = zeros(size(self.results{it,e}.TranAvg.Q));
%                     for i=1:size(self.results{it,e}.TranAvg.Q,1)
%                         for r=1:size(self.results{it,e}.TranAvg.Q,2)
%                             w{e,h} = [0, map_cdf(self.envMMAP{e,h}, self.results{it,e}.TranAvg.Q{i,r}(2:end,2)) - map_cdf(self.envMMAP{e,h}, self.results{it,e}.TranAvg.Q{i,r}(1:end-1,2))]';
%                             if ~isnan(w{e,h})
%                                 QE{e,h}(i,r) = self.results{it,e}.TranAvg.Q{i,r}(:,1)'*w{e,h}/sum(w{e,h});
%                             else
%                                 QE{e,h}(i,r) = 0;
%                             end
%                         end
%                     end
%                 end
            end
                        
            Qval=0*QExit{e};
            Uval=0*UExit{e};
            Tval=0*TExit{e};
            for e=1:E
               Qval = Qval + self.probEnv(e) * QExit{e}; % to check
               Uval = Uval + self.probEnv(e) * UExit{e}; % to check
               Tval = Tval + self.probEnv(e) * TExit{e}; % to check
            end            
            self.result.Avg.Q = Qval;
            %    self.result.Avg.R = R;
            %    self.result.Avg.X = X;
            self.result.Avg.U = Uval;
            self.result.Avg.T = Tval;
            %    self.result.Avg.C = C;
            %self.result.runtime = runtime;
        end
        
        function name = getName(self)
            name = mfilename;
        end
        
        function [QNclass, UNclass, TNclass] = getAvg(self)
            if isempty(self.result) || (isfield(self.options,'force') && self.options.force)
                self.run();
                if isempty(self.result)
                    QNclass=[];
                    UNclass=[];
                    TNclass=[];
                    return
                end
            end
            QNclass = self.result.Avg.Q;
            UNclass = self.result.Avg.U;
            TNclass = self.result.Avg.T;
        end
    end
    
    methods (Static)
        function [bool, featSupported] = supports(model)
            featUsed = model.getUsedLangFeatures();
            
            featSupported = SolverFeatureSet;
            
            % Nodes
            featSupported.setTrue('ClassSwitch');
            featSupported.setTrue('DelayStation');
            featSupported.setTrue('Queue');
            featSupported.setTrue('Sink');
            featSupported.setTrue('Source');
            
            % Distributions
            featSupported.setTrue('Cox2');
            featSupported.setTrue('Erlang');
            featSupported.setTrue('Exponential');
            featSupported.setTrue('HyperExp');
            
            % Sections
            featSupported.setTrue('StatelessClassSwitcher'); % Section
            featSupported.setTrue('InfiniteServer'); % Section
            featSupported.setTrue('SharedServer'); % Section
            featSupported.setTrue('Buffer'); % Section
            featSupported.setTrue('Dispatcher'); % Section
            featSupported.setTrue('Server'); % Section (Non-preemptive)
            featSupported.setTrue('JobSink'); % Section
            featSupported.setTrue('RandomSource'); % Section
            featSupported.setTrue('ServiceTunnel'); % Section
            
            % Scheduling strategy
            featSupported.setTrue('SchedStrategy_INF');
            featSupported.setTrue('SchedStrategy_PS');
            featSupported.setTrue('RoutingStrategy_PROB');
            featSupported.setTrue('RoutingStrategy_RAND');
            featSupported.setTrue('RoutingStrategy_RR'); % with SolverJMT
            
            % Customer Classes
            featSupported.setTrue('ClosedClass');
            featSupported.setTrue('OpenClass');
            
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
end

