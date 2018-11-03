function [rt, rtfun, csmask] = refreshRoutingMatrix(self, rates)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

if nargin == 1
    if isempty(self.qn)
        error('refreshRoutingMatrix cannot retrieve station rates, pass them as an input parameters.');
    else
        rates = self.qn.rates;
    end
end

qn = self.qn;
M = self.getNumberOfNodes;
K = self.getNumberOfClasses();
arvRates = zeros(1,K);
for r = self.getIndexOpenClasses
    arvRates(r) = rates(self.getIndexSourceStation,r);
end

[rt, rtnodes, ~, ~, linksmat] = self.getRoutingMatrix(arvRates);

rnodefuncell = cell(M*K,M*K);
stateful = self.getIndexStatefulNodes;
for ind=1:M % source
    for jnd=1:M % source
        for r=1:K
            for s=1:K
                if qn.isstatedep(ind,3)
                    switch qn.routing(ind)
                        case RoutingStrategy.ID_RR
                            rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(state_before, state_after) sub_rr(ind, jnd, r, s, linksmat, state_before, state_after);
                        case RoutingStrategy.ID_JSQ
                            rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(state_before, state_after) sub_jsq(ind, jnd, r, s, linksmat, state_before, state_after);
                    end
                else
                    rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(~,~) rtnodes((ind-1)*K+r, (jnd-1)*K+s);
                end
            end
        end
    end
end

csmask = false(K,K);
for ind=1:M % source
    for jnd=1:M % source
        for r=1:K
            for s=1:K
                if r==s
                    csmask(r,s) = true;
                else
                    if isa(self.nodes{ind}.server,'ClassSwitchSection')
                        if self.nodes{ind}.server.csFun(r,s,[],[])>0
                            csmask(r,s) = true;
                        end
                    end
                end
            end
        end
    end
end

statefulNodesClasses = [];
for ind=self.getIndexStatefulNodes()
    statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
end

% we now generate the node routing matrix for the given state and then
% lump the states for non-stateful nodes so that run gives the routing
% touble for stateful nodes only
statefulNodesClasses = [];
for ind=stateful
    statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
end


rtfunraw = @(state_before, state_after) dtmc_stochcomp(cell2mat(cellfun(@(f) f(state_before, state_after), rnodefuncell,'UniformOutput',false)), statefulNodesClasses);
rtfun = rtfunraw;
%rtfun = memoize(rtfunraw); % memoize to reduce the number of stoch comp calls
%rtfun.CacheSize = 6000^2;

if ~isempty(self.qn)
    self.qn.rt = rt;
    self.qn.rtnodes = rtnodes;
    self.qn.setRoutingFunction(rtfun, csmask);
end

    function p = sub_rr(ind, jnd, r, s, linksmat, state_before, state_after)
        isf = qn.nodeToStateful(ind);
        if isempty(state_before{isf})
            p = min(linksmat(ind,jnd),1);
        else
            if r==s
                p = double(state_after{isf}(end-r+1)==jnd);
            else
                p = 0;
            end
        end
    end

    function p = sub_jsq(ind, jnd, r, s, linksmat, state_before, state_after) %#ok<INUSD>
        isf = qn.nodeToStateful(ind);
        if isempty(state_before{isf})
            p = min(linksmat(ind,jnd),1);
        else
            if r==s
                n = Inf*ones(1,qn.nnodes);
                for knd=1:qn.nnodes
                    if linksmat(ind,knd)
                        ksf = qn.nodeToStateful(knd);
                        n(knd) = State.toMarginal(qn, knd, state_before{ksf});
                    end
                end
                if n(jnd) == min(n)
                    p = 1 / sum(n == min(n));
                else
                    p = 0;
                end
            else
                p = 0;
            end
        end
    end
end