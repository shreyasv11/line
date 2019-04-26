function nvars = refreshLocalVars(self)
% NVARS = REFRESHLOCALVARS()

nvars = zeros(self.getNumberOfNodes, 1);
varsparam = cell(self.getNumberOfNodes, 1);
rtnodes = self.qn.rtnodes;
for ind=1:self.getNumberOfNodes
    switch class(self.nodes{ind})
        case 'Cache'
            nvars(ind) = sum(self.nodes{ind}.itemLevelCap);
            varsparam{ind} = struct();
            varsparam{ind}.nitems = 0;
            varsparam{ind}.accost = self.nodes{ind}.accessCost;
            for r=1:self.getNumberOfClasses
                if ~self.nodes{ind}.popularity{r}.isDisabled
                    varsparam{ind}.nitems = max(varsparam{ind}.nitems,self.nodes{ind}.popularity{r}.support(2));
                end
            end
            varsparam{ind}.cap = self.nodes{ind}.itemLevelCap;
            varsparam{ind}.pref = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                if self.nodes{ind}.popularity{r}.isDisabled
                    varsparam{ind}.pref{r} = NaN;
                else
                    varsparam{ind}.pref{r} = self.nodes{ind}.popularity{r}.evalPMF(1:varsparam{ind}.nitems);
                end
            end
            varsparam{ind}.rpolicy = self.nodes{ind}.replacementPolicy;
            varsparam{ind}.hitclass = self.nodes{ind}.server.hitClass;
            varsparam{ind}.missclass = self.nodes{ind}.server.missClass;
    end
    switch self.qn.routing(ind)
        case RoutingStrategy.ID_RR
            nvars(ind) = nvars(ind) + 1;
            % save indexes of outgoing links
            if isempty(varsparam) % reinstantiate if not a cache
                varsparam{ind} = struct();
            end
            varsparam{ind}.outlinks = find(sum(reshape(rtnodes(ind,:)>0,self.qn.nnodes,self.qn.nclasses),2)');
    end
end
if ~isempty(self.qn) %&& isprop(self.qn,'nvars')
    self.qn.setLocalVars(nvars, varsparam);
end
end
