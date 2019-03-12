classdef NetworkSolver < Solver
    % Copyright (c) 2012-2018, Imperial College London
    % All rights reserved.
    
    
    properties
        handles;
    end
    
    methods
        %Constructor
        function self = NetworkSolver(model, name, options)
            self = self@Solver(model, name);
            if exist('options','var'), self.setOptions(options); end
            self.result = [];
            self.handles.Q = [];
            self.handles.U = [];
            self.handles.W = [];
            self.handles.T = [];
            sa = model.getStruct(); % force model to refresh
        end
    end
    
    methods(Access = 'protected')
        function bool = hasAvgResults(self)
            bool = false;
            if self.hasResults
                if isfield(self.result,'Avg')
                    bool = true;
                end
            end
        end
        
        function bool = hasTranResults(self)
            bool = false;
            if self.hasResults
                bool = isfield(self.result.TranAvg,'Qt');
            end
        end
        
        function bool = hasDistribResults(self)
            bool = false;
            if self.hasResults
                bool = isfield(self.result.Distrib,'C');
            end
        end
    end
    
    methods
        function self = updateModel(self, model)
            self.model = model;
        end
        
        function ag = getAG(self)
            ag = self.model.getAG();
        end
        
        function qn = getStruct(self)
            qn = self.model.getStruct();
        end
        
        function QN = getAvgQLen(self)
            Q = self.model.getAvgQLenHandles();
            [QN,~,~,~] = self.getAvg(Q,[],[],[]);
        end
        
        function UN = getAvgUtil(self)
            U = self.model.getAvgUtilHandles();
            [~,UN,~,~] = self.getAvg([],U,[],[]);
        end
        
        function RN = getAvgRespT(self)
            R = self.model.getAvgRespTHandles();
            [~,~,RN,~] = self.getAvg([],[],R,[]);
        end
        
        function TN = getAvgTput(self)
            T = self.model.getAvgTputHandles();
            [~,~,~,TN] = self.getAvg([],[],[],T);
        end
        
        function AN = getAvgArvR(self)
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
            % update tputs for all nodes but the sink
            for ind=1:I
                if qn.nodetype(ind) ~= NodeType.Sink
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
    [NodeAvgTable,QTn,UTn,RTn,TTn] = getNodeAvgTable(self,Q,U,R,T,keepDisabled);
    [QNc,UNc,RNc,TNc]   = getAvgChain(self,Q,U,R,T);
    [CNc,XNc]           = getAvgSys(self,R,T);
    [AN]                = getAvgArvRChain(self,Q);
    [QN]                = getAvgQLenChain(self,Q);
    [UN]                = getAvgUtilChain(self,U);
    [RN]                = getAvgRespTChain(self,R);
    [TN]                = getAvgTputChain(self,T);
    [RN]                = getAvgSysRespT(self,R);
    [TN]                = getAvgSysTput(self,T);
    [CT,XT]             = getAvgSysTable(self,R,T);
    [QNt,UNt,TNt] = getTranAvg(self,Qt,Ut,Tt);
    
    function self = setAvgResults(self,Q,U,R,T,C,X,runtime)
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
    end
    
    function self = setCdfResults(self,Cd,runtime)
    self.result.('solver') = self.getName();
    self.result.Distrib.('method') = self.getOptions().method;
    self.result.Distrib.C = Cd;
    self.result.Distrib.runtime = runtime;
    end
    
    function self = setTranAvgResults(self,Qt,Ut,Rt,Tt,Ct,Xt,runtimet)
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
    
    % default warnings for advanced features to be over-ridden in subclasses
    function [lNormConst] = getProbNormConst(self)
    error('getProbNormConst is not supported by this solver.');
    end
    
    function Pnir = getProbState(self)
    error('getProbState is not supported by this solver.');
    end
    
    function Pnjoint = getProbStateSys(self)
    error('getStateSysProb is not supported by this solver.');
    end
    
    function RD = getCdfRespT(self, R)
    error('getCdfRespT is not supported by this solver.');
    end
    
    function RD = getTranCdfRespT(self, R)
    error('getTranCdfRespT is not supported by this solver.');
    end
    
    function RD = getTranCdfPassT(self, R)
    error('getTranCdfPassT is not supported by this solver.');
    end
    
end

end