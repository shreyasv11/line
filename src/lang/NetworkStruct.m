classdef NetworkStruct < matlab.mixin.Copyable
    % Copyright (c) 2012-2018, Imperial College London
    % All rights reserved.
    
    properties
        cap;     % total buffer size
        chains;     % binary CxK matrix where 1 in entry (i,j) indicates that class j is in chain i.
        classcap;    % buffer size for each class
        classnames;  % name of each job class
        classprio;       % scheduling priorities in each class (optional)
        csmask; % (r,s) entry if class r can switch into class s somewhere
        %forks;      % forks table from each station
        % (MKxMK matrix with integer entries), indexed first by
        % station, then by class
        isstatedep; % state dependent routing
        isstation; % element i is true if node i is a station
        isstateful; % element i is true if node i is stateful
        mu;          % service rate in each service phase, for each job class in each station
        % (MxK cell with n_{i,k}x1 double entries)
        nchains;           % number of chains (int)
        nclasses;          % number of classes (int)
        nclosedjobs;          % total population (int)
        njobs;             % initial distribution of jobs in classes (Kx1 int)
        nnodes; % number of nodes (Mn int)
        nservers;   % number of servers per station (Mx1 int)
        nstations;  % number of stations (int)
        nstateful;  % number of stations (int)
        nvars; % number of local variables
        nodenames;   % name of each node
        nodetype; % server type in each node
        phases; % number of phases in each service or arrival process
        phi;         % probability of service completion in each service phase,
        % for each job class in each station
        % (MxK cell with n_{i,k}x1 double entries)
        rates;       % service rate for each job class in each station
        refstat;    % index of the reference node for each request class (Kx1 int)
        routing;     % routing strategy type
        rt;         % routing table with class switching
        % (M*K)x(M*K) matrix with double entries), indexed first by
        % station, then by class
        rtnodes;         % routing table with class switching
        % (Mn*K)x(Mn*K) matrix with double entries), indexed first by
        % node, then by class
        rtfun; % local routing functions
        % (Mn*K)x(Mn*K) matrix with double entries), indexed first by
        % station, then by class
        sched;       % scheduling strategy in each station
        schedid;       % scheduling strategy id in each station (optional)
        schedparam;       % scheduling weights in each station and class (optional)
        sync;
        space;    % state space
        state;    % initial or current state
        scv; % squared coefficient of variation of service times (MxK)
        visits;           % visits placed by classes at the resources
        varsparam;     % parameters for local variables
    end
    
    methods
        %constructor
        function self = NetworkStruct(nodetype, nodenames, classnames, numservers, njobs, refstat, routing)
            self.nnodes = numel(nodenames);
            self.nstations = length(numservers);
            self.nclasses = length(classnames);
            self.nclosedjobs = sum(njobs(isfinite(njobs)));
            self.nservers = numservers;
            self.nodetype = -1*ones(self.nstations,1);
            self.scv = ones(self.nstations,self.nclasses);
            %self.forks = zeros(M,K);
            self.njobs = njobs(:)';
            self.refstat = refstat;
            self.space = cell(self.nstations,1);
            self.routing = routing;
            self.chains = [];
            if exist('nvars','var') && ~isempty(nvars)
                self.nvars = nvars;
            end
            if exist('nodetype','var') && ~isempty(nodetype)
                self.nodetype = nodetype;
                self.isstation = NodeType.isStation(nodetype);
                self.isstateful = NodeType.isStateful(nodetype);
                self.isstatedep = false(self.nnodes,3); % col 1: buffer, col 2: srv, col 3: routing
                for ind=1:self.nnodes
                    switch self.nodetype(ind)
                        case NodeType.Cache
                            self.isstatedep(ind,2) = true; % state dependent service                  
                    end
                    for r=1:self.nclasses
                        switch self.routing(ind,r)
                            case {RoutingStrategy.ID_RR, RoutingStrategy.ID_JSQ}
                                self.isstatedep(ind,3) = true; % state dependent routing                  
                        end
                    end
                end
                self.nstateful = sum(self.isstateful);
                self.state = cell(self.nstations,1); for i=1:self.nstateful self.state{i} = []; end
            end
            if exist('nodenames','var')
                self.nodenames = nodenames;
            else
                self.nodenames = cell(self.nnodes,1);
                for j = 1:self.nstations
                    self.nodenames{j,1} = int2str(j);
                end
            end
            if exist('classnames','var')
                self.classnames = classnames;
            else
                self.classnames = cell(self.nclasses,1);
                for j = 1:self.nclasses
                    self.classnames{j,1} = int2str(j);
                end
            end
            
            self.reindex();
        end
        
        function reindex(self)
            for ind=1:self.nnodes
                self.nodeToStateful(ind) = self.nd2sf(ind);
                self.nodeToStation(ind) = self.nd2st(ind);
            end
            for ist=1:self.nstations
                self.stationToNode(ist) = self.st2nd(ist);
                self.stationToStateful(ist) = self.st2sf(ist);
            end
            for isf=1:self.nstateful
                self.statefulToNode(isf) = self.sf2nd(isf);
            end            
        end
        
        function setChains(self, chains, visits, rt)
            self.chains = logical(chains);
            self.visits = visits;
            self.rt = rt;
            self.nchains = size(chains,1);
        end
        
        function setSched(self, sched, schedparam)
            self.sched = sched;
            self.schedparam = schedparam;
            self.schedid = zeros(self.nstations,1);
            for i=1:self.nstations
                self.schedid(i) = SchedStrategy.toId(sched{i});
            end
        end
        
        function setService(self, rates, scv)
            self.rates = rates;
            self.scv = scv;
        end
        
        function setCoxService(self, mu, phi, phases)
            self.mu = mu;
            self.phi = phi;
            self.phases = phases;
        end
        
        function setCapacity(self, cap, classcap)
            self.cap = cap;
            self.classcap = classcap;
        end
        
        function setPrio(self, prio)
            self.classprio = prio;
        end
        
        function setSync(self, sync)
            self.sync = sync;
        end
        
        function setLocalVars(self, nvars, varsparam)
            self.nvars = nvars;
            self.varsparam = varsparam;
        end
        
        function setRoutingFunction(self, rtfun, csmask)
            self.rtfun = rtfun;
            self.csmask = csmask;
        end
    end
    
    properties (Access = public)
        nodeToStateful;
        nodeToStation;
        stationToNode;
        stationToStateful;
        statefulToNode;
    end
    
    methods % index conversion
        function stat_idx = nd2st(self, node_idx)
            if self.isstation(node_idx)
                stat_idx = at(cumsum(self.isstation),node_idx);
            else
                stat_idx = NaN;
            end
        end
        
        function node_idx = st2nd(self,stat_idx)
            v = cumsum(self.isstation) == stat_idx;
            if any(v)
                node_idx =  find(v, 1);
            else
                node_idx = NaN;
            end
        end
        
        function sful_idx = st2sf(self,stat_idx)
            sful_idx = nd2sf(self,st2nd(self,stat_idx));
        end
        
        function sful_idx = nd2sf(self, node_idx)
            if self.isstateful(node_idx)
                sful_idx = at(cumsum(self.isstateful),node_idx);
            else
                sful_idx = NaN;
            end
        end
        
        function node_idx = sf2nd(self,stat_idx)
            v = cumsum(self.isstateful) == stat_idx;
            if any(v)
                node_idx =  find(v, 1);
            else
                node_idx = NaN;
            end
        end
    end % getIndex
end