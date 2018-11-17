classdef Network < matlab.mixin.Copyable
    % Copyright (c) 2012-2018, Imperial College London
    % All rights reserved.
    
    properties (GetAccess = 'private', SetAccess='private')
        modelName;
        usedFeatures; % structure of booleans listing the used classes
        % it must be accessed via getUsedLangFeatures that updates
        % the Distribution classes dynamically
        isInitialized;
        logPath;
        linkedP;
    end
    
    properties (Access=protected)
        items;
    end
    
    properties (Hidden)
        qn;
        ag;
        handles;
        perfIndex;
        links;
    end
    
    properties
        classes;
        stations;
        nodes;
    end
    
    methods % public methods in class folder
        refreshAG(self) % get agent representation
        
        sa = getStruct(self, structType, wantState) % get abritrary representation
        %        cn = getCN(self, wantState) % wrapper of getStruct for cache network representation
        %        ag = getAG(self) % get agent representation
        
        used = getUsedLangFeatures(self) % get used features
        
        ft = getForks(self, rt) % get fork table
        [chainsObj,chainsMatrix] = getChains(self, rt) % get chain table
        
        [P,Pnodes,myPc,myPs,links] = getRoutingMatrix(self, arvRates) % get routing matrix
        
        nodes = resetNetwork(self)
        self = link(self, P)
        [loggerBefore,loggerAfter] = linkAndLog(self, nodes, classes, P, wantLogger, logPath)
        function self = linkNetwork(self, P) % obsolete - old name
            self = link(self,  P); 
        end 
        function [loggerBefore,loggerAfter] = linkNetworkAndLog(self, nodes, classes, P, wantLogger, logPath)% obsolete - old name
            [loggerBefore,loggerAfter] = linkAndLog(self, nodes, classes, P, wantLogger, logPath); 
        end 
        
        [Q,U,R,T] = getAvgHandles(self)
        T = getAvgTputHandles(self);
        Q = getAvgQLenHandles(self);
        R = getAvgRespTHandles(self);
        U = getAvgUtilHandles(self);
        [Qt,Ut,Tt] = getTranHandles(self)
    end
    
    methods (Access = protected)
        [rates, scv] = refreshRates(self);
        [mu, phi, phases] = refreshCoxService(self);
        [rt, rtnodes, csmask] = refreshRoutingMatrix(self, rates);
        sync = refreshSync(self);
        sanitize(self);
    end
    
    methods
        classprio = refreshPriorities(self);
        [sched, schedid, schedparam] = refreshScheduling(self, rates);
        function [rates, mu, phi, phases] = refreshArrival(self) % LINE treats arrival distributions as service distributions of the Source object
            [rates, mu, phi, phases] = self.refreshService();
        end
        [rates, scv, mu, phi, phases] = refreshService(self);
        [chains, visits, rt] = refreshChains(self, rates, wantVisits)
        [cap, classcap] = refreshCapacity(self);
        nvars = refreshLocalVars(self);
    end
    
    % PUBLIC METHODS
    methods
        %Constructor
        function self = Network(modelName)
            self.nodes = {};
            self.stations = {};
            self.classes = {};
            self.perfIndex = struct();
            self.perfIndex.('Avg') = {};
            self.perfIndex.('Tran') = {};
            self.links = {};
            self.setName(modelName);
            self.initUsedFeatures();
            self.qn = [];
            self.linkedP = {};
            self.ag = [];
            self.isInitialized = false;
            self.logPath = '';
            self.items = {};
        end
        
        function nodes = getNodes(self)
            nodes = self.nodes;
        end
        
        function P = getLinkedRoutingMatrix(self)
            if isempty(self.linkedP)
                error('Unsupported. To use this function the model topology must have been linked with the link method.');
            else
                P = self.linkedP;
            end
        end
        
        function logPath = getLogPath(self)
            logPath = self.logPath;
        end
        
        function setLogPath(self, logPath)
            self.logPath = logPath;
        end
        
        function bool = hasInitState(self)
            bool = true;
            if ~self.isInitialized % check if all stations are initialized
                for ind=1:self.getNumberOfNodes
                    if isa(self.nodes{ind},'StatefulNode') && isempty(self.nodes{ind}.state)
                        bool = false;
                    end
                end
            end
        end
        
        function reset(self)
            self.perfIndex.Avg = {};
            self.perfIndex.Tran = {};
            self.handles = {};
            self.qn = [];
            self.ag = [];
        end
        
        refreshStruct(self);
        
        function [M,R] = getSize(self)
            M = self.getNumberOfNodes;
            R = self.getNumberOfClasses;
        end
        
        function bool = hasOpenClasses(self)
            bool = any(isinf(self.getNumberOfJobs()));
        end
        
        function bool = hasClassSwitch(self)
            bool = any(cellfun(@(c) isa(c,'ClassSwitch'), self.nodes));
        end
        
        function bool = hasClosedClasses(self)
            bool = any(isfinite(self.getNumberOfJobs()));
        end
        
        function index = getIndexOpenClasses(self)
            index = find(isinf(self.getNumberOfJobs()))';
        end
        
        function index = getIndexClosedClasses(self)
            index = find(isfinite(self.getNumberOfJobs()))';
        end
        
        function c = getClassChain(self, className)
            chains = self.getChains;
            if ischar(className)
                for c = 1:length(chains)
                    if any(cell2mat(strfind(chains{c}.classnames,className)))
                        return
                    end
                end
            else
                for c = 1:length(chains)
                    if any(cell2mat(chains{c}.index==1))
                        return
                    end
                end
            end
            c = -1;
        end
        
        function classnames = getClassNames(self)
            for r=1:getNumberOfClasses(self)
                classnames{r,1}=self.classes{r}.name;
            end
        end
        
        function nodeNames = getNodeNames(self)
            for i=1:getNumberOfNodes(self)
                nodeNames{i,1} = self.nodes{i}.name;
            end
        end
        
        function nodeTypes = getNodeTypes(self)
            nodeTypes = zeros(self.getNumberOfNodes,1);
            for i=1:self.getNumberOfNodes
                switch class(self.nodes{i})
                    case 'Cache'
                        nodeTypes(i) = NodeType.Cache;
                    case 'Logger'
                        nodeTypes(i) = NodeType.Logger;
                    case 'ClassSwitch'
                        nodeTypes(i) = NodeType.ClassSwitch;
                    case {'Queue','QueueingStation'}
                        nodeTypes(i) = NodeType.Queue;
                    case 'Router'
                        nodeTypes(i) = NodeType.Dispatcher;
                    case {'Delay','DelayStation'}
                        nodeTypes(i) = NodeType.Delay;
                    case 'Sink'
                        nodeTypes(i) = NodeType.Sink;
                    case 'Source'
                        nodeTypes(i) = NodeType.Source;
                end
            end
        end

        function rtTypes = getRoutingStrategies(self)
            rtTypes = zeros(self.getNumberOfNodes,self.getNumberOfClasses);
            for ind=1:self.getNumberOfNodes
                for r=1:self.getNumberOfClasses
                    switch self.nodes{ind}.output.outputStrategy{r}{2}
                        case RoutingStrategy.RAND
                            rtTypes(ind,r) = RoutingStrategy.ID_RAND;
                        case RoutingStrategy.PROB
                            rtTypes(ind,r) = RoutingStrategy.ID_PROB;
                        case RoutingStrategy.RR
                            rtTypes(ind,r) = RoutingStrategy.ID_RR;
                        case RoutingStrategy.JSQ
                            rtTypes(ind,r) = RoutingStrategy.ID_JSQ;
                    end
                end
            end
        end
        
        function nodeIndex = getNodeIndex(self, name)
            nodeIndex = find(cellfun(@(c) strcmp(c,name),self.getNodeNames));
        end
        
        function stationIndex = getStationIndex(self, name)
            stationIndex = find(cellfun(@(c) strcmp(c,name),self.getStationNames));
        end
        
        function classIndex = getClassIndex(self, name)
            classIndex = find(cellfun(@(c) strcmp(c,name),self.getClassNames));
        end
        
        function stationnames = getStationNames(self)
            stationnames = {};
            for i=self.getIndexStations
                stationnames{end+1,1} = self.nodes{i}.name;
            end
        end
        
        function statefulnames = getStatefulNodeNames(self)
            statefulnames = {};
            for i=1:self.getNumberOfNodes
                if self.nodes{i}.isStateful
                    statefulnames{end+1,1} = self.nodes{i}.name;
                end
            end
        end
        
        function M = getNumberOfNodes(self)
            M = length(self.nodes);
        end
        
        function S = getNumberOfStatefulNodes(self)
            S = sum(cellisa(self.nodes,'StatefulNodes'));
        end
        
        function M = getNumberOfStations(self)
            M = length(self.stations);
        end
        
        function R = getNumberOfClasses(self)
            R = length(self.classes);
        end
        
        function C = getNumberOfChains(self)
            qn = self.getStruct;
            C = qn.nchains;
        end
        
        function out = getName(self)
            out = self.modelName;
        end
        
        function Dchain = getDemandsChain(self)
            qn = self.getStruct;
            M = qn.nstations;    %number of stations
            K = qn.nclasses;    %number of classes
            mu = qn.mu;
            phi = qn.phi;
            C = qn.nchains;
            
            PH=cell(M,K);
            for i=1:M
                for k=1:K
                    if length(mu{i,k})==1
                        PH{i,k} = map_exponential(1/mu{i,k});
                    else
                        D0 = diag(-mu{i,k})+diag(mu{i,k}(1:end-1).*(1-phi{i,k}(1:end-1)),1);
                        D1 = zeros(size(D0));
                        D1(:,1)=(phi{i,k}.*mu{i,k});
                        PH{i,k} = map_normalize({D0,D1});
                    end
                end
            end
            
            % determine service times
            ST = zeros(M,K);
            for k = 1:K
                for i=1:M
                    ST(i,k) = 1 ./ map_lambda(PH{i,k});
                end
            end
            ST(isnan(ST))=0;
            
            alpha = zeros(qn.nstations,qn.nclasses);
            Vchain = zeros(qn.nstations,qn.nchains);
            for c=1:qn.nchains
                inchain = find(qn.chains(c,:));
                for i=1:qn.nstations
                    Vchain(i,c) = sum(qn.visits{c}(i,inchain)) / sum(qn.visits{c}(qn.refstat(inchain(1)),inchain));
                    for k=inchain
                        alpha(i,k) = alpha(i,k) + qn.visits{c}(i,k) / sum(qn.visits{c}(i,inchain));
                    end
                end
            end
            Vchain(~isfinite(Vchain))=0;
            alpha(~isfinite(alpha))=0;
            
            Dchain = zeros(M,C);
            STchain = zeros(M,C);
            
            refstatchain = zeros(C,1);
            for c=1:qn.nchains
                inchain = find(qn.chains(c,:));
                isOpenChain = any(isinf(qn.njobs(inchain)));
                for i=1:qn.nstations
                    % we assume that the visits in L(i,inchain) are equal to 1
                    STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
                    if isOpenChain && i == qn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
                        STchain(i,c) = 1 / sumfinite(qn.rates(i,inchain)); % ignore degenerate classes with zero arrival rates
                    else
                        STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
                    end
                    Dchain(i,c) = Vchain(i,c) * STchain(i,c);
                end
                refstatchain(c) = qn.refstat(inchain(1));
                if any((qn.refstat(inchain(1))-refstatchain(c))~=0)
                    error(sprintf('Classes in chain %d have different reference station.',c));
                end
            end
            Dchain(~isfinite(Dchain))=0;
        end
        
        % Set attributes
        function self = setName(self, modelName)
            self.modelName = modelName;
        end
        
        % setUsedFeatures : records that a certain language feature has been used
        function self = setUsedFeatures(self,className)
            self.usedFeatures.setTrue(className);
        end
        
        %% Add the components to the model
        addJobClass(self, customerClass);
        addNode(self, node);
        addLink(self, nodeA, nodeB);
        addLinks(self, nodeList);
        
        addPerfIndex(self, performanceIndex);
        self = disablePerfIndex(self, Y);
        self = enablePerfIndex(self, Y);
        
        node = getSource(self);
        node = getSink(self);
        
        function list = getIndexStations(self)
            % returns the ids of nodes that are stations
            list = find(cellisa(self.nodes, 'Station'))';
        end
        
        function list = getIndexStatefulNodes(self)
            % returns the ids of nodes that are stations
            list = find(cellisa(self.nodes, 'StatefulNode'))';
        end
        
        %% Analysis of model features and available solvers
        
        %         function listAvailableSolvers(self)
        %             fprintf(1,'This model can be analyzed by the following solvers:\n');
        %             if SolverMVA.supports(self)
        %                 fprintf(1,'SolverMVA\n');
        %             end
        %             if SolverCTMC.supports(self)
        %                 fprintf(1,'SolverCTMC\n');
        %             end
        %             if SolverFluid.supports(self)
        %                 fprintf(1,'SolverFluid\n');
        %             end
        %             if SolverJMT.supports(self)
        %                 fprintf(1,'SolverJMT\n');
        %             end
        %             if SolverSSA.supports(self)
        %                 fprintf(1,'SolverSSA\n');
        %             end
        %         end
        
        index = getIndexSourceStation(self);
        index = getIndexSourceNode(self);
        index = getIndexSinkNode(self);
        
        N = getNumberOfJobs(self);
        refstat = getReferenceStations(self);
        sched = getStationScheduling(self);
        S = getStationServers(self);
        
        function jsimwView(self)
            s=SolverJMT(self,struct(),jmtGetPath); s.jsimwView;
        end
        
        function jsimgView(self)
            s=SolverJMT(self,struct(),jmtGetPath); s.jsimgView;
        end
        
        function [ni, nir, sir, kir] = initToMarginal(self)
            ni = {}; nir = {}; sir = {}; kir = {};
            qn = self.getStruct;
            for ist=1:length(self.stations)
                if ~isempty(self.stations{ist}.getState())
                    [ni{ist,1}, nir{ist,1}, sir{ist,1}, kir{ist,1}] = State.toMarginal(qn,qn.stationToNode(ist),state);
                end
            end
        end
        
        function [isvalid] = isStateValid(self)
            qn = self.getStruct;
            nir = [];
            sir = [];
            for ist=1:qn.nstations
                isf = qn.stationToStateful(ist);
                [~, nir(ist,:), sir(ist,:), ~] = State.toMarginal(qn, qn.stationToNode(ist), qn.state{isf});
            end
            isvalid = State.isValid(qn, nir, sir);
        end
        
        function [initialState, priorInitialState] = getState(self) % get initial state
            if ~self.hasInitState
                self.initDefault;
            end
            initialState = {};
            priorInitialState = {};
            for ind=1:length(self.nodes)
                if self.nodes{ind}.isStateful
                    initialState{end+1,1} = self.nodes{ind}.getState();
                    priorInitialState{end+1,1} = self.nodes{ind}.getStatePrior();
                end
            end
        end
        
        function initFromAvgQLen(self, AvgQLen)
            n = round(AvgQLen);
            njobs = sum(n,1);
            % we now address the problem that round([0.5,0.5]) = [1,1] so
            % different from the total initial population
            for r=1:size(AvgQLen,2)
                if njobs(r) > sum(AvgQLen,1) % error at most by 1
                    i = maxpos(n(:,r));
                    n(i,r) = n(i,r) - 1;
                    njobs = sum(n,1)';
                end
            end
            self.initFromMarginal(n);
        end
        
        function initDefault(self)
            % open classes empty
            % closed classes initialized at ref station
            % running jobs are allocated in class id order until all
            % servers are busy
            self.refreshStruct();  % we force update of the model before we initialize
            qn = self.getStruct(false);
            N = qn.njobs';
            for i=1:self.getNumberOfNodes
                if qn.isstation(i)
                    n0 = zeros(1,length(N));
                    s0 = zeros(1,length(N));
                    s = qn.nservers(qn.nodeToStation(i)); % allocate
                    for r=find(isfinite(N))' % for all closed classes
                        if qn.nodeToStation(i) == qn.refstat(r)
                            n0(r) = N(r);
                        end
                        s0(r) = min(n0(r),s);
                        s = s - s0(r);
                    end
                    state_i = State.fromMarginalAndStarted(qn,i,n0(:)',s0(:)');
                    switch qn.nodetype(i)
                        case NodeType.Cache
                            state_i = [state_i, 1:qn.nvars(i)];
                    end
                    switch qn.routing(i)
                        case RoutingStrategy.ID_RR
                            % start from first connected queue
                            state_i = [state_i, find(qn.rt(i,:),1)];
                    end
                    if isempty(state_i)
                        error('Default initialization failed on station %d.',i);
                    else
                        self.nodes{i}.setState(state_i);
                        prior_state_i = zeros(1,size(state_i,1)); prior_state_i(1) = 1;
                        self.nodes{i}.setStatePrior(prior_state_i);
                    end
                elseif qn.isstateful(i) % not a station
                    switch class(self.nodes{i})
                        case 'Cache'
                            state_i = zeros(1,self.getNumberOfClasses);
                            state_i = [state_i, 1:sum(self.nodes{i}.itemLevelCap)];
                            self.nodes{i}.setState(state_i);
                        otherwise
                            self.nodes{i}.setState([]);
                    end
                    %error('Default initialization not available on stateful node %d.',i);
                end
            end
            %if self.isStateValid % problem with example_initState_2
            self.isInitialized = true;
            %else
            %    error('Default initialization failed.');
            %end
        end
        
        function initFromMarginal(self, n, options) % n(i,r) : number of jobs of class r in node i
            qn = self.getStruct();
            if ~exist('options','var')
                options = Solver.defaultOptions;
            end
            [isvalidn] = State.isValid(qn, n, [], options);
            if ~isvalidn
                error('The specified state does not have the correct number of jobs.');
            end
            for ind=1:qn.nnodes
                if qn.isstateful(ind)
                    ist = qn.nodeToStation(ind);
                    self.nodes{ind}.setState(State.fromMarginal(qn,ind,n(ist,:)));
                    if isempty(self.nodes{ind}.getState)
                        error(sprintf('Invalid state assignment for station %d.',ind));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function initFromMarginalAndRunning(self, n, s, options) % n(i,r) : number of jobs of class r in node i
            qn = self.getStruct();
            [isvalidn] = State.isValid(qn, n, s);
            if ~isvalidn
                error('Initial state is not valid.');
            end
            for i=1:self.getNumberOfNodes
                if self.nodes{i}.isStateful
                    self.nodes{i}.setState(State.fromMarginalAndRunning(qn,i,n(i,:),s(i,:)));
                    if isempty(self.nodes{i}.getState)
                        error(sprintf('Invalid state assignment for station %d\n',i));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function initFromMarginalAndStarted(self, n, s, options) % n(i,r) : number of jobs of class r in node i
            qn = self.getStruct();
            [isvalidn] = State.isValid(qn, n, s);
            if ~isvalidn
                error('Initial state is not valid.');
            end
            for ind=1:self.getNumberOfNodes
                if self.nodes{ind}.isStateful
                    ist = qn.nodeToStation(ind);
                    self.nodes{ind}.setState(State.fromMarginalAndStarted(qn,ind,n(ist,:),s(ist,:)));
                    if isempty(self.nodes{ind}.getState)
                        error(sprintf('Invalid state assignment for station %d\n',ind));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function [H,G] = getGraph(self)
            G = digraph(); TG = table();
            M = self.getNumberOfNodes;
            K = self.getNumberOfClasses;
            qn = self.getStruct;
            [P,Pnodes] = self.getRoutingMatrix();
            name = {}; sched = {}; type = {};
            for i=1:M
                name{end+1} = self.nodes{i}.name;
                type{end+1} = class(self.nodes{i});
                sched{end+1} = self.nodes{i}.schedStrategy;
            end
            TG.Name = name(:);
            TG.Type = type(:);
            TG.Sched = sched(:);
            G = G.addnode(TG);
            for i=1:M
                for j=1:M
                    for k=1:K
                        if Pnodes((i-1)*K+k,(j-1)*K+k) > 0
                            G = G.addedge(self.nodes{i}.name,self.nodes{j}.name, Pnodes((i-1)*K+k,(j-1)*K+k));
                        end
                    end
                end
            end
            H = digraph(); TH = table();
            I = self.getNumberOfStations;
            name = {}; sched = {}; type = {}; jobs = zeros(I,1);
            for i=1:I
                name{end+1} = self.stations{i}.name;
                type{end+1} = class(self.stations{i});
                sched{end+1} = self.stations{i}.schedStrategy;
                for k=1:K
                    if qn.refstat(k)==i
                        jobs(i) = jobs(i) + qn.njobs(k);
                    end
                end
            end
            TH.Name = name(:);
            TH.Type = type(:);
            TH.Sched = sched(:);
            TH.Jobs = jobs(:);
            H = H.addnode(TH);
            rate = [];
            classes = {};
            for i=1:I
                for j=1:I
                    for k=1:K
                        if P((i-1)*K+k,(j-1)*K+k) > 0
                            rate(end+1) = qn.rates(i,k);
                            classes{end+1} = self.classes{k}.name;
                            H = H.addedge(self.stations{i}.name, self.stations{j}.name, P((i-1)*K+k,(j-1)*K+k));
                        end
                    end
                end
            end
            H.Edges.Rate = rate(:);
            H.Edges.Class = classes(:);
            H = H.rmedge(find(isnan(H.Edges.Rate)));
            sourceObj = self.getSource;
            if ~isempty(sourceObj)
                %                 sink = self.getSink;
                %                 H=H.addnode(sink.name);
                %                 H.Nodes.Type{end}='Sink';
                %                 H.Nodes.Sched{end}='ext';
                %H = H.rmedge(find(isnan(H.Edges.Rate)));
                %sourceIdx = model.getIndexSourceNode;
                %                toDel = findstring(H.Edges.EndNodes(:,2),sourceObj.name);
                %                for j=toDel(:)'
                %                    H = H.rmedge(j);
                %                end
            end
        end
        
        function mask = getClassSwitchingMask(self)
            mask = self.getStruct.csmask;
        end
        
        function printRoutingMatrix(self)
            node_names = self.getNodeNames;
            classnames = self.getClassNames;
            [~,Pnodes] = self.getRoutingMatrix(); % get routing matrix
            M = self.getNumberOfNodes;
            K = self.getNumberOfClasses;
            for i=1:M
                for r=1:K
                    for j=1:M
                        for s=1:K
                            if Pnodes((i-1)*K+r,(j-1)*K+s)>0
                                fprintf('%s [class: %s] => %s [class: %s] : Pr=%f\n',node_names{i}, classnames{r}, node_names{j}, classnames{s},Pnodes((i-1)*K+r,(j-1)*K+s));
                            end
                        end
                    end
                end
            end
        end
        
        %        function self = isValid(self)
        %% todo
        %        end
        function self = update(self)
            self.refreshStruct();
        end
        
    end
    
    % Private methods
    methods (Access = 'private')
        
        function out = getmodelNameExtension(self)
            out = [getmodelName(self), ['.', self.fileFormat]];
        end
        
        function self = initUsedFeatures(self)
            % The list includes all classes but Model and Hidden or
            % Constant or Abstract or Solvers
            self.usedFeatures = SolverFeatureSet;
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % Make a shallow copy of all properties
            clone = copyElement@matlab.mixin.Copyable(self);
            % Make a deep copy of each handle
            for i=1:length(self.classes)
                clone.classes{i} = self.classes{i}.copy;
            end
            % Make a deep copy of each handle
            for i=1:length(self.nodes)
                clone.nodes{i} = self.nodes{i}.copy;
                if isa(clone.nodes{i},'Station')
                    clone.stations{i} = clone.nodes{i};
                end
                for l=1:length(self.links)
                    for j=1:length(self.links{l})
                        if strcmp(self.links{l}{1}.name, self.nodes{i}.name)
                            clone.links{l}{1} = clone.nodes{i};
                        end
                        if strcmp(self.links{l}{2}.name, self.nodes{i}.name)
                            clone.links{l}{2} = clone.nodes{i};
                        end
                    end
                end
            end
            
            % PerfIndex objects do not contain object handles
            for i=1:length(self.perfIndex.Avg)
                clone.perfIndex.Avg{i} = self.perfIndex.Avg{i}.copy;
            end
            for i=1:length(self.perfIndex.Tran)
                clone.perfIndex.Tran{i} = self.perfIndex.Tran{i}.copy;
            end
        end
    end
    
    methods
        function bool = hasFCFS(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.FCFS);
            if i > 0, bool = true; end
        end
        
        function bool = hasHomogeneousScheduling(self, strategy)
            bool = length(findstring(self.getStruct.sched,strategy)) == self.getStruct.nstations;
        end
        
        function bool = hasDPS(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.DPS);
            if i > 0, bool = true; end
        end
        
        function bool = hasGPS(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.GPS);
            if i > 0, bool = true; end
        end
        
        function bool = hasINF(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.INF);
            if i > 0, bool = true; end
        end
        
        function bool = hasPS(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.PS);
            if i > 0, bool = true; end
        end
        
        function bool = hasRAND(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.RAND);
            if i > 0, bool = true; end
        end
        
        function bool = hasHOL(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.HOL);
            if i > 0, bool = true; end
        end
        
        function bool = hasLCFS(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.LCFS);
            if i > 0, bool = true; end
        end
        
        function bool = hasSEPT(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.SEPT);
            if i > 0, bool = true; end
        end
        
        function bool = hasLEPT(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.LEPT);
            if i > 0, bool = true; end
        end
        
        function bool = hasSJF(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.SJF);
            if i > 0, bool = true; end
        end
        
        function bool = hasLJF(self)
            bool = false;
            i = findstring(self.getStruct.sched,SchedStrategy.LJF);
            if i > 0, bool = true; end
        end
        
        function bool = hasMultiClassFCFS(self)
            i = findstring(self.getStruct.sched,SchedStrategy.FCFS);
            if i > 0
                bool = range([self.getStruct.rates(i,:)])>0;
            else
                bool = false;
            end
        end
        
        function bool = hasMultiServer(self)
            bool = any(self.getStruct.nservers(isfinite(self.getStruct.nservers)) > 1);
        end
        
        function bool = hasSingleChain(self)
            bool = self.getNumberOfChains == 1;
        end
        
        function bool = hasMultiChain(self)
            bool = self.getNumberOfChains > 1;
        end
        
        function bool = hasSingleClass(self)
            bool = self.getNumberOfClasses == 1;
        end
        
        function bool = hasMultiClass(self)
            bool = self.getNumberOfClasses > 1;
        end
        
        function bool = hasProductFormSolution(self)
            bool = true;
            % language features
            featUsed = self.getUsedLangFeatures().list;
            if featUsed.ForkStation, bool = false; end
            if featUsed.JoinStation, bool = false; end
            if featUsed.MMPP2, bool = false; end
            if featUsed.Normal, bool = false; end
            if featUsed.Pareto, bool = false; end
            if featUsed.Replayer, bool = false; end
            if featUsed.Uniform, bool = false; end
            if featUsed.Fork, bool = false; end
            if featUsed.Join, bool = false; end
            if featUsed.SchedStrategy_LCFS, bool = false; end % must be LCFS-PR
            if featUsed.SchedStrategy_SJF, bool = false; end
            if featUsed.SchedStrategy_LJF, bool = false; end
            if featUsed.SchedStrategy_DPS, bool = false; end
            if featUsed.SchedStrategy_GPS, bool = false; end
            if featUsed.SchedStrategy_SEPT, bool = false; end
            if featUsed.SchedStrategy_LEPT, bool = false; end
            if featUsed.SchedStrategy_HOL, bool = false; end
            % modelling features
            if self.hasMultiClassFCFS, bool = false; end
        end
        
        
        function addItemSet(self, itemSet)
            if sum(cellfun(@(x) strcmp(x.name, itemSet.name), self.items))>0
                error('An item type with name %s already exists.\n', itemSet.name);
            end            
            nItemSet = size(self.items,1);
            itemSet.index = nItemSet+1;
            self.items{end+1,1} = itemSet;
            self.setUsedFeatures(class(itemSet)); 
        end        
    end
    
    methods (Static)
        function model = tandemPs(lambda,D)
            model = Network.tandemPsInf(lambda,D,[]);
        end
        
        function model = tandemPsInf(lambda,D,Z)
            if ~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.PS;
            end
            model = Network.tandem(lambda,[D;Z],strategy);
        end
        
        function model = tandemFcfs(lambda,D)
            model = Network.tandemFcfsInf(lambda,D,[]);
        end
        
        function model = tandemFcfsInf(lambda,D,Z)
            if ~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.FCFS;
            end
            model = Network.tandem(lambda,[D;Z],strategy);
        end
        
        function model = tandem(lambda,S,strategy)
            % S(i,r) - mean service time of class r at station i
            % lambda(r) - number of jobs of class r
            % station(i) - scheduling strategy at station i
            model = Network('Model');
            [M,R] = size(S);
            node{1} = Source(model, 'Source');
            for i=1:M
                switch strategy{i}
                    case SchedStrategy.INF
                        node{end+1} = DelayStation(model, ['Station',num2str(i)]);
                    otherwise
                        node{end+1} = Queue(model, ['Station',num2str(i)], strategy{i});
                end
            end
            node{end+1} = Sink(model, 'Sink');
            P = {};
            for r=1:R
                jobclass{r} = OpenClass(model, ['Class',num2str(r)], 0);
                P{r} = circul(length(node)); P{r}(end,:) = 0;
            end
            for r=1:R
                node{1}.setArrival(jobclass{r}, Exp.fitMeanAndSCV(1/lambda(r)));
                for i=1:M
                    node{1+i}.setService(jobclass{r}, Exp.fitMeanAndSCV(S(i,r)));
                end
            end
            model.link(P);
        end
        
        function model = cyclicPs(N,D)
            model = Network.cyclicPsInf(N,D,[]);
        end
        
        function model = cyclicPsInf(N,D,Z)
            if ~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.PS;
            end
            model = Network.cyclic(N,[D;Z],strategy);
        end
        
        function model = cyclicFcfs(N,D)
            model = Network.cyclicFcfsInf(N,D,[]);
        end
        
        function model = cyclicFcfsInf(N,D,Z)
            if ~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.FCFS;
            end
            model = Network.cyclic(N,[D;Z],strategy);
        end
        
        function model = cyclic(N,D,strategy)
            % L(i,r) - demand of class r at station i
            % N(r) - number of jobs of class r
            % strategy(i) - scheduling strategy at station i
            model = Network('Model');
            options = Solver.defaultOptions;
            [M,R] = size(D);
            node = {};
            for i=1:M
                switch strategy{i}
                    case SchedStrategy.INF
                        node{end+1} = DelayStation(model, ['Station',num2str(i)]);
                    otherwise
                        node{end+1} = Queue(model, ['Station',num2str(i)], strategy{i});
                end
            end
            for r=1:R
                jobclass{r} = ClosedClass(model, ['Class',num2str(r)], N(r), node{1}, 0);
                P{r} = circul(M);
            end
            for i=1:M
                for r=1:R
                    node{i}.setService(jobclass{r}, Exp.fitMeanAndSCV(D(i,r)));
                end
            end
            model.link(P);
        end
        
        function P = serialRouting(varargin)
            P = zeros(length(varargin));
            for i=1:length(varargin)-1
                P(varargin{i},varargin{i+1})=1;
            end
            if ~isa(varargin{end},'Sink')
                P(varargin{end},varargin{1})=1;
            end
            P = P ./ repmat(sum(P,2),1,length(P));
            P(isnan(P)) = 0;
        end

        
    end
end