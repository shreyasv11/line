classdef Station < StatefulNode
    % An abstract class for nodes where jobs station
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        numberOfServers;
        numberOfServerPhases;
        cap;
        classCap;
    end
    
    methods(Hidden)
        %Constructor
        function self = Station(name)
            self@StatefulNode(name);
            self.cap = Inf;
            self.classCap = [];
            self.numberOfServerPhases = [];
        end
    end
    
    methods
        function setNumServers(self, value)
            self.numberOfServers = value;
        end
        
        function setNumberOfServers(self, value)
            self.numberOfServers = value;
        end
        
        function value = getNumServers(self)
            value = self.numberOfServers;
        end
        
        function value = getNumberOfServers(self)
            value = self.numberOfServers;
        end
        
        function setCapacity(self, value)
            self.cap = value;
        end
        
        function setChainCapacity(self, values)
            qn = self.model.getStruct;
            if numel(values) ~= qn.nchains
                error('The method requires in input a capacity value for each chain.');
            end
            for c = 1:qn.nchains
                inchain = find(qn.chains(c,:));
                for r = inchain
                    if ~self.isServiceDisabled(r)
                        self.classCap(r) = values(c);
                    else
                        self.classCap(r) = Inf;
                    end
                end
            end
            self.cap = min(sum(self.classCap(self.classCap>0)), self.cap);
        end
        
        function K = getNumberOfServerPhases(self)
            R = size(self.server.serviceProcess,2);
            if isempty(self.numberOfServerPhases)
                K = zeros(1,R);
                for r=1:R
                    K(r) = self.server.serviceProcess{1,r}{end}.getNumberOfPhases();
                end
                self.numberOfServerPhases = K;
            else
                K = self.numberOfServerPhases;
            end
        end
        
        function isD = isServiceDisabled(self, class)
            switch self.server.className
                case 'ServiceTunnel'
                    isD = false;
                otherwise
                    isD = self.server.serviceProcess{1,class}{end}.isDisabled();
            end
        end
        
        function isI = isServiceImmediate(self, class)
            isI = self.server.serviceProcess{1,class}{end}.isImmediate();
        end
        
        function R = getNumberOfServiceClasses(self)
            R = size(self.server.serviceProcess,2);
        end
        
        function [R,K,S] = getStationParams(self)
            R = self.getNumberOfServiceClasses();
            K = self.getNumberOfServerPhases();
            S = self.numberOfServers;
        end
        
        function [p] = getSelfLoopProbabilities(self)
            R = self.getNumberOfServiceClasses();
            p = zeros(1,R);
            for k=1:R
                nOutLinks = length(self.output.outputStrategy{k}{end});
                switch RoutingStrategy.toText(self.output.outputStrategy{k}{2})
                    case 'Random'
                        p(k) = 1 / nOutLinks;
                    case 'Probabilities'
                        for t=1:nOutLinks % for all outgoing links
                            if strcmp(self.output.outputStrategy{k}{end}{t}{1}.name, self.name)
                                p(k) = self.output.outputStrategy{k}{end}{t}{2};
                                break
                            end
                        end
                end
            end
        end
        
        function [mu,phi] = getCoxSourceRates(self)
            R = size(self.input.sourceClasses,2);
            mu = cell(1,R);
            phi = cell(1,R);
            for r=1:R
                if isempty(self.input.sourceClasses{r})
                    self.input.sourceClasses{r} = {[],ServiceStrategy.LI,Disabled()};
                    mu{r}  = NaN;
                    phi{r} = NaN;
                elseif ~self.input.sourceClasses{r}{end}.isDisabled()
                    switch class(self.input.sourceClasses{r}{end})
                        case 'Replayer'
                            [mu{r}, phi{r}] = self.input.sourceClasses{r}{end}.fitCoxian();
                        case 'Exp'
                            mu{r} = self.input.sourceClasses{r}{end}.params{1}.paramValue;
                            phi{r} = 1;
                        case {'APH','MarkovianDistribution'}
                            % TO CHANGE
                            % Get the closest approximation in Coxian form
                            PH = self.input.sourceClasses{r}{end}.getRepresentation;
                            mu{r} = -diag(PH{1});
                            phi{r} = sum(PH{2},2) ./ mu{r}; % completion rate
                        case 'Coxian'
                            if self.input.sourceClasses{r}{end}.getNumParams == 2
                                mua = self.input.sourceClasses{r}{end}.params{1}.paramValue;
                                phia = self.input.sourceClasses{r}{end}.params{2}.paramValue;
                                mu{r} = mua;
                                phi{r} = phia;
                            else
                                mu1 = self.input.sourceClasses{r}{end}.params{1}.paramValue;
                                mu2 = self.input.sourceClasses{r}{end}.params{2}.paramValue;
                                p = self.input.sourceClasses{r}{end}.params{3}.paramValue;
                                mu{r} = [mu1;mu2];
                                phi{r} = [p;1.0];
                            end
                        case 'HyperExp'
                            PH = self.input.sourceClasses{r}{end}.getRepresentation;
                            mu{r} = -diag(PH{1});
                            phi{r} = sum(PH{2},2) ./ mu{r}; % completion rate
                        case 'Erlang'
                            mu1 = self.input.sourceClasses{r}{end}.params{1}.paramValue;
                            k = self.input.sourceClasses{r}{end}.params{2}.paramValue;
                            mu{r} = mu1*ones(k,1);
                            phi{r} = zeros(k,1); phi{r}(end)=1;
                    end
                else
                    mu{r} = NaN;
                    phi{r} = NaN;
                end
            end
        end
        
        function [ph] = getPHSourceRates(self)
            nclasses = size(self.input.sourceClasses,2);
            ph = cell(1,nclasses);
            for r=1:nclasses
                if isempty(self.input.sourceClasses{r})
                    self.input.sourceClasses{r} = {[],ServiceStrategy.LI,Disabled()};
                    ph{r}  = {[NaN],[NaN]};
                elseif ~self.input.sourceClasses{r}{end}.isDisabled()
                    switch class(self.input.sourceClasses{r}{end})
                        case 'Replayer'
                            ph{r} = self.input.sourceClasses{r}{end}.fitPhaseType.getRepresentation();
                        case {'Exp','Coxian','Erlang','HyperExp','MarkovianDistribution','APH'}
                            ph{r} = self.input.sourceClasses{r}{end}.getRepresentation;
                    end
                else
                    ph{r}  = {[NaN],[NaN]};
                end
            end
        end
        
        function [mu,phi] = getCoxServiceRates(self)
            R = size(self.server.serviceProcess,2);
            mu = cell(1,R);
            phi = cell(1,R);
            for r=1:R
                if isempty(self.server.serviceProcess{r})
                    self.server.serviceProcess{r} = {[],ServiceStrategy.LI,Disabled()};
                    mu{r}  = NaN;
                    phi{r} = NaN;
                elseif self.server.serviceProcess{r}{end}.isImmediate()
                    mu{r} = Distrib.InfRate;
                    phi{r} = 1;
                elseif ~self.server.serviceProcess{r}{end}.isDisabled()
                    switch class(self.server.serviceProcess{r}{end})
                        case 'Replayer'
                            cox = self.server.serviceProcess{r}{end}.fitCoxian();
                            mu{r} = cox.getMu;
                            phi{r} = cox.getPhi;
                        case 'Exp'
                            mu{r} = self.server.serviceProcess{r}{end}.params{1}.paramValue;
                            phi{r} = 1;
                        case {'APH','MarkovianDistribution'}
                            % Get the closest approximation in Coxian form
                            %[~, mu{r}, phi{r}] = Coxian.fitMeanAndSCV(map_mean(PH), map_scv(PH));
                            PH = self.server.serviceProcess{r}{end}.getRepresentation;
                            mu{r} = -diag(PH{1});
                            phi{r} = sum(PH{2},2) ./ mu{r}; % completion rate
                        case 'Coxian'
                            if self.server.serviceProcess{r}{end}.getNumParams == 2
                                mua = self.server.serviceProcess{r}{end}.params{1}.paramValue;
                                phia = self.server.serviceProcess{r}{end}.params{2}.paramValue;
                                mu{r} = mua;
                                phi{r} = phia;
                            else
                                mu1 = self.server.serviceProcess{r}{end}.params{1}.paramValue;
                                mu2 = self.server.serviceProcess{r}{end}.params{2}.paramValue;
                                p = self.server.serviceProcess{r}{end}.params{3}.paramValue;
                                mu{r} = [mu1;mu2];
                                phi{r} = [p;1.0];
                            end
                        case 'HyperExp'
                            PH = self.server.serviceProcess{r}{end}.getRepresentation;
                            %                            p = self.server.serviceProcess{r}{end}.params{1}.paramValue;
                            %                            mu1 = self.server.serviceProcess{r}{end}.params{2}.paramValue;
                            %                            mu2 = self.server.serviceProcess{r}{end}.params{3}.paramValue;
                            %                            PH = {[-mu1,0;0,-mu2],[mu1*p,mu1*(1-p);mu2*p,mu2*(1-p)]};
                            %                            [~, mu{r}, phi{r}] = Coxian.fitMeanAndSCV(map_mean(PH), map_scv(PH));
                            mu{r} = -diag(PH{1});
                            phi{r} = sum(PH{2},2) ./ mu{r}; % completion rate
                        case 'Erlang'
                            mu1 = self.server.serviceProcess{r}{end}.params{1}.paramValue;
                            k = self.server.serviceProcess{r}{end}.params{2}.paramValue;
                            mu{r} = mu1*ones(k,1);
                            phi{r} = zeros(k,1); phi{r}(end)=1;
                    end
                else
                    mu{r} = NaN;
                    phi{r} = NaN;
                end
            end
        end
        
        function [ph] = getPHServiceRates(self)
            nclasses = size(self.server.serviceProcess,2);
            ph = cell(1,nclasses);
            for r=1:nclasses
                if isempty(self.server.serviceProcess{r})
                    self.server.serviceProcess{r} = {[],ServiceStrategy.LI,Disabled()};
                    ph{r}  = {[NaN],[NaN]};
                elseif self.server.serviceProcess{r}{end}.isImmediate()
                    ph{r}  = {[Distrib.InfRate],[1]};
                elseif ~self.server.serviceProcess{r}{end}.isDisabled()
                    switch class(self.server.serviceProcess{r}{end})
                        case 'Replayer'
                            ph{r} = self.server.serviceProcess{r}{end}.fitAPH().getRepresentation();
                        case {'Exp','Coxian','Erlang','HyperExp','MarkovianDistribution','APH'}
                            ph{r} = self.server.serviceProcess{r}{end}.getRepresentation();
                    end
                else
                    ph{r}  = {[NaN],[NaN]};
                end
            end
        end
    end
end