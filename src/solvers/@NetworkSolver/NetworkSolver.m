classdef NetworkSolver < Solver
    % Abstract class for solvers applicable to Network models.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    
    properties (Access = protected)
        handles; % performance metric handles
    end
    
    methods
        function self = NetworkSolver(model, name, options)
            % Construct a NetworkSolver with given model, name and options
            % data structure.
            self@Solver(model, name);
            if exist('options','var'), self.setOptions(options); end
            self.result = [];
            self.handles.Q = [];
            self.handles.U = [];
            self.handles.W = [];
            self.handles.T = [];
            model.refreshStruct(); % force model to refresh
        end
    end
    
    methods (Access = 'protected')
        function bool = hasAvgResults(self)
            % Returns true if the solver has computed steady-state average metrics.
            bool = false;
            if self.hasResults
                if isfield(self.result,'Avg')
                    bool = true;
                end
            end
        end
        
        function bool = hasTranResults(self)
            % Return true if the solver has computed transient average metrics.
            bool = false;
            if self.hasResults
                bool = isfield(self.result.TranAvg,'Qt');
            end
        end
        
        function bool = hasDistribResults(self)
            % Return true if the solver has computed steady-state distribution metrics.
            bool = false;
            if self.hasResults
                bool = isfield(self.result.Distrib,'C');
            end
        end
    end
    
    methods
        function self = updateModel(self, model)
            % Assign the model to be solved.
            self.model = model;
        end
        
        function ag = getAG(self)
            % Get agent representation
            ag = self.model.getAG();
        end
        
        function qn = getStruct(self)
            % Get data structure summarizing the model
            qn = self.model.getStruct();
        end
        
        function QN = getAvgQLen(self)
            % Compute average queue-lengths at steady-state
            Q = self.model.getAvgQLenHandles();
            [QN,~,~,~] = self.getAvg(Q,[],[],[]);
        end
        
        function UN = getAvgUtil(self)
            % Compute average utilizations at steady-state
            U = self.model.getAvgUtilHandles();
            [~,UN,~,~] = self.getAvg([],U,[],[]);
        end
        
        function RN = getAvgRespT(self)
            % Compute average response times at steady-state
            R = self.model.getAvgRespTHandles();
            [~,~,RN,~] = self.getAvg([],[],R,[]);
        end
        
        function TN = getAvgTput(self)
            % Compute average throughputs at steady-state
            T = self.model.getAvgTputHandles();
            [~,~,~,TN] = self.getAvg([],[],[],T);
        end
        
        function AN = getAvgArvR(self)
            % Compute average arrival rate at steady-state
            M = self.model.getNumberOfStations;
            K = self.model.getNumberOfClasses;
            T = self.model.getAvgTputHandles();
            [~,~,~,TN] = self.getAvg([],[],[],T);
            qn = self.model.getStruct;
            if ~isempty(T)
                AN = zeros(M,K);
                for k=1:K
                    for i=1:M
                        for j=1:M
                            for r=1:K
                                AN(i,k) = AN(i,k) + TN(j,r)*qn.rt((j-1)*K+r, (i-1)*K+k);
                            end
                        end
                    end
                end
            end
        end
        
        function [QNn,UNn,RNn,TNn] = getNodeAvg(self, Q, U, R, T)
            % Compute average utilizations at steady-state for all nodes
            if nargin == 1 % no parameter
                if isempty(self.model.handles) || ~isfield(self.model.handles,'Q') || ~isfield(self.model.handles,'U') || ~isfield(self.model.handles,'R') || ~isfield(self.model.handles,'T')
                    self.reset(); % reset in case there are partial results saved
                end
                [Q,U,R,T] = self.model.getAvgHandles;
            elseif nargin == 2
                handlers = Q;
                Q=handlers{1};
                U=handlers{2};
                R=handlers{3};
                T=handlers{4};
            end
            qn = self.model.getStruct;
            [QN,UN,RN,TN] = self.getAvg(Q,U,R,T);
            I = self.model.getNumberOfNodes;
            M = self.model.getNumberOfStations;
            R = self.model.getNumberOfClasses;
            C = self.model.getNumberOfChains;
            QNn = zeros(I,R);
            UNn = zeros(I,R);
            RNn = zeros(I,R);
            TNn = zeros(I,R);
            for ist=1:M
                ind = qn.stationToNode(ist);
                QNn(ind,:) = QN(ist,:);
                UNn(ind,:) = UN(ist,:);
                RNn(ind,:) = RN(ist,:);
                TNn(ind,:) = TN(ist,:);
            end
            % update tputs for all nodes but the sink and the joins
            for ind=1:I
                if qn.nodetype(ind) ~= NodeType.Sink && qn.nodetype(ind) ~= NodeType.Join
                    if qn.isstatedep(ist,3) % if state-dep routing
                        error('getNodeAvg does not support models with state-dependent routing.');
                    else
                        for c = 1:C
                            inchain = find(qn.chains(c,:));
                            for r = inchain
                                anystat = find(qn.visits{c}(:,r));
                                if ~isempty(anystat)
                                    anystat = anystat(1);
                                    TNn(ind, r) =  (qn.nodevisits{c}(ind,r) / qn.visits{c}(anystat,r)) * TN(anystat,r);
                                end
                            end
                        end
                    end
                    TNn(isnan(TNn)) = 0;
                end
            end
            % now update sink
            for ind=1:I
                if qn.nodetype(ind) == NodeType.Sink
                    for jnd=1:I
                        for k=1:R
                            for r=1:R
                                TNn(ind, k) = TNn(ind, k) + TNn(jnd,r)*qn.rtnodes((jnd-1)*R+r, (ind-1)*R+k);
                            end
                        end
                    end
                end
            end
        end
        
        % also accepts a cell array with the handlers in it
        [QN,UN,RN,TN]       = getAvg(self,Q,U,R,T);
        
        [AvgTable,QT,UT,RT,TT] = getAvgTable(self,Q,U,R,T,keepDisabled);
        [AvgTable,QT] = getAvgQLenTable(self,Q,keepDisabled);
        [AvgTable,UT] = getAvgUtilTable(self,U,keepDisabled);
        [AvgTable,RT] = getAvgRespTTable(self,R,keepDisabled);
        [AvgTable,TT] = getAvgTputTable(self,T,keepDisabled);
        
        [NodeAvgTable,QTn,UTn,RTn,TTn] = getNodeAvgTable(self,Q,U,R,T,keepDisabled);
        
        [QNc,UNc,RNc,TNc]   = getAvgChain(self,Q,U,R,T);
        
        [AN]                = getAvgArvRChain(self,Q);
        
        [QN]                = getAvgQLenChain(self,Q);
        
        [UN]                = getAvgUtilChain(self,U);
        
        [RN]                = getAvgRespTChain(self,R);
        
        [TN]                = getAvgTputChain(self,T);
        
        [CNc,XNc]           = getAvgSys(self,R,T);
        
        [CT,XT]             = getAvgSysTable(self,R,T);
        
        [RN]                = getAvgSysRespT(self,R);
        
        [TN]                = getAvgSysTput(self,T);
        
        [QNt,UNt,TNt]       = getTranAvg(self,Qt,Ut,Tt);
        
        function self = setAvgResults(self,Q,U,R,T,C,X,runtime)
            % Store average metrics at steady-state
            self.result.('solver') = self.getName();
            self.result.Avg.('method') = self.getOptions().method;
            if isnan(Q), Q=[]; end
            if isnan(R), R=[]; end
            if isnan(T), T=[]; end
            if isnan(U), U=[]; end
            if isnan(X), X=[]; end
            if isnan(C), C=[]; end
            self.result.Avg.Q = Q;
            self.result.Avg.R = R;
            self.result.Avg.X = X;
            self.result.Avg.U = U;
            self.result.Avg.T = T;
            self.result.Avg.C = C;
            self.result.Avg.runtime = runtime;
            if self.getOptions().verbose
                try
                    solvername = erase(self.result.solver,'Solver');
                catch
                    solvername = self.result.solver(7:end);
                end
                fprintf(1,'%s analysis (method: %s) completed in %f seconds.\n',solvername,self.result.Avg.method,runtime);
            end
        end
        
        function self = setDistribResults(self,Cd,runtime)
            % Store distribution metrics at steady-state
            self.result.('solver') = self.getName();
            self.result.Distrib.('method') = self.getOptions().method;
            self.result.Distrib.C = Cd;
            self.result.Distrib.runtime = runtime;
        end
        
        function self = setTranAvgResults(self,Qt,Ut,Rt,Tt,Ct,Xt,runtimet)
            % Store transient average metrics
            self.result.('solver') = self.getName();
            self.result.TranAvg.('method') = self.getOptions().method;
            for i=1:size(Qt,1), for r=1:size(Qt,2), if isnan(Qt{i,r}), Qt={}; end, end, end
            for i=1:size(Rt,1), for r=1:size(Rt,2), if isnan(Rt{i,r}), Rt={}; end, end, end
            for i=1:size(Ut,1), for r=1:size(Ut,2), if isnan(Ut{i,r}), Ut={}; end, end, end
            for i=1:size(Tt,1), for r=1:size(Tt,2), if isnan(Tt{i,r}), Tt={}; end, end, end
            for i=1:size(Xt,1), for r=1:size(Xt,2), if isnan(Xt{i,r}), Xt={}; end, end, end
            for i=1:size(Ct,1), for r=1:size(Ct,2), if isnan(Ct{i,r}), Ct={}; end, end, end
            self.result.TranAvg.Q = Qt;
            self.result.TranAvg.R = Rt;
            self.result.TranAvg.U = Ut;
            self.result.TranAvg.T = Tt;
            self.result.TranAvg.X = Xt;
            self.result.TranAvg.C = Ct;
            self.result.TranAvg.runtime = runtimet;
        end
        
        function [lNormConst] = getProbNormConst(self)
            % Return normalizing constant of state probabilities
            error('getProbNormConst is not supported by this solver.');
        end
        
        function Pstate = getProbState(self, ist)
            % Return marginal state probability for station ist state
            error('getProbState is not supported by this solver.');
        end
        
        function Psysstate = getProbSysState(self)
            % Return joint state probability
            error('getStateSysProb is not supported by this solver.');
        end
        
        function Pnir = getProbStateAggr(self, ist)
            % Return marginal state probability for station ist state
            error('getProbStateAggr is not supported by this solver.');
        end
        
        function Pnjoint = getProbSysStateAggr(self)
            % Return joint state probability
            error('getProbSysStateAggr is not supported by this solver.');
        end

        function tstate = getTranState(self, ist)
            % Return marginal state probability for station ist state
            error('getTranState is not supported by this solver.');
        end
        
        function tnir = getTranStateAggr(self, ist)
            % Return marginal state probability for station ist state
            error('getTranStateAggr is not supported by this solver.');
        end
        
        function tsysstate = getTranSysState(self)
            % Return joint state probability
            error('getTranSysState is not supported by this solver.');
        end
        
        function tnjoint = getTranSysStateAggr(self)
            % Return joint state probability
            error('getTranSysStateAggr is not supported by this solver.');
        end        
        
        function RD = getCdfRespT(self, R)
            % Return cumulative distribution of response times at steady-state
            error('getCdfRespT is not supported by this solver.');
        end
        
        function RD = getTranCdfRespT(self, R)
            % Return cumulative distribution of response times during transient
            error('getTranCdfRespT is not supported by this solver.');
        end
        
        function RD = getTranCdfPassT(self, R)
            % Return cumulative distribution of passage times at steady-state
            error('getTranCdfPassT is not supported by this solver.');
        end
    end
    methods (Static)
        function solvers = getAllSolvers(model, options)
            % Return a cell array with all Network solvers
            if ~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            solvers{end+1} = SolverCTMC(model, options);
            solvers{end+1} = SolverJMT(model, options);
            solvers{end+1} = SolverSSA(model, options);
            solvers{end+1} = SolverFluid(model, options);
            solvers{end+1} = SolverMAM(model, options);
            solvers{end+1} = SolverMVA(model, options);
            solvers{end+1} = SolverNC(model, options);
        end
        
        function solvers = getAllFeasibleSolvers(model, options)
            % Return a cell array with all Network solvers feasible for
            % this model
            if ~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            if SolverCTMC.supports(model)
                solvers{end+1} = SolverCTMC(model, options);
            end
            if SolverJMT.supports(model)
                solvers{end+1} = SolverJMT(model, options);
            end
            if SolverSSA.supports(model)
                solvers{end+1} = SolverSSA(model, options);
            end
            if SolverFluid.supports(model)
                solvers{end+1} = SolverFluid(model, options);
            end
            if SolverMAM.supports(model)
                solvers{end+1} = SolverMAM(model, options);
            end
            if SolverMVA.supports(model)
                solvers{end+1} = SolverMVA(model, options);
            end
            if SolverNC.supports(model)
                solvers{end+1} = SolverNC(model, options);
            end
        end
        
    end
    
end