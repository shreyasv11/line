function [chains, visits, rt] = refreshChains(self, rates, wantVisits)
% [CHAINS, VISITS, RT] = REFRESHCHAINS(RATES, WANTVISITS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

if ~exist('wantVisits','var')
    wantVisits = true;
end

if nargin == 1
    if isempty(self.qn)
        error('refreshRoutingMatrix cannot retrieve station rates, please pass them as an input parameters.');
    else
        rates = self.qn.rates;
    end
end

I = self.getNumberOfNodes();
M = self.getNumberOfStatefulNodes();
K = self.getNumberOfClasses();
refstat = self.getReferenceStations();
[rt,~,csmask, rtnodes] = self.refreshRoutingMatrix(rates);
% getChains
[C,inChain] = weaklyconncomp(csmask+csmask');
%[C,inChain] = weaklyconncomp(rt+rt')

chainCandidates = cell(1,C);
for c=1:C
    chainCandidates{c} = find(inChain==c);
end

chains = [];
for t=1:length(chainCandidates)
    %    if length(chainCandidates{t})>1
    %        chains(end+1,unique(mod(chainCandidates{t}-1,K)+1)) = true;
    chains(end+1,chainCandidates{t}) = true;
    %    end
end

try
    chains = sortrows(chains,'descend');
catch
    chains = sortrows(chains);
end

for c=1:size(chains,1)
    inchain = find(chains(c,:));
    if sum(refstat(inchain) == refstat(inchain(1))) ~= length(inchain)
        refstat(inchain) = refstat(inchain(1));
        %        error(sprintf('Classes in chain %d have different reference stations. Chain %d classes: %s', c, c, int2str(inchain)));
    end
end

visits = cell(size(chains,1),1); % visits{c}(i,j) is the number of visits that a chain-c job pays at node i in class j
if wantVisits
    for c=1:size(chains,1)
        inchain = find(chains(c,:));
        
        %% stations
        cols = [];
        for i=1:M
            for k=inchain(:)'
                cols(end+1) = (i-1)*K+k;
            end
        end
        Pchain = rt(cols,cols); % routing probability of the chain
        visited = sum(Pchain,2) > 0;
        %                Pchain(visited,visited)
        %                if ~dtmc_isfeasible(Pchain(visited,visited))
        %                    error(sprintf('The routing matrix in chain %d is not stochastic. Chain %d classes: %s',c, c, int2str(inchain)));
        %                end
        alpha_visited = dtmc_solve(Pchain(visited,visited));
        alpha = zeros(1,M*K); alpha(visited) = alpha_visited;
        if max(alpha)>=1-1e-10
            %disabled because a self-looping customer is an absorbing chain
            %error('Line:ChainAbsorbingState','One chain has an absorbing state.');
        end
        visits{c} = zeros(M,K);        
        for i=1:M            
            for k=1:length(inchain)
                visits{c}(i,inchain(k)) = alpha((i-1)*length(inchain)+k);
            end
        end
        visits{c} = visits{c} / sum(visits{c}(refstat(inchain(1)),inchain));
        visits{c} = abs(visits{c});
        
        %% nodes
        nodes_cols = [];
        for i=1:I
            for k=inchain(:)'
                nodes_cols(end+1) = (i-1)*K+k;
            end
        end
        nodes_Pchain = rtnodes(nodes_cols,nodes_cols); % routing probability of the chain
        nodes_visited = sum(nodes_Pchain,2) > 0;
        
        %                Pchain(visited,visited)
        %                if ~dtmc_isfeasible(Pchain(visited,visited))
        %                    error(sprintf('The routing matrix in chain %d is not stochastic. Chain %d classes: %s',c, c, int2str(inchain)));
        %                end
        nodes_alpha_visited = dtmc_solve(nodes_Pchain(nodes_visited,nodes_visited));
        nodes_alpha = zeros(1,I); nodes_alpha(nodes_visited) = nodes_alpha_visited;
        if max(nodes_alpha)>=1-1e-10
            %disabled because a self-looping cusotmer has an absobring
            %chain
            %error('Line:ChainAbsorbingState','One chain has an absorbing state.');
        end
        nodevisits{c} = zeros(I,K);
        for i=1:I
            for k=1:length(inchain)
                nodevisits{c}(i,inchain(k)) = nodes_alpha((i-1)*length(inchain)+k);
            end
        end
        nodevisits{c} = nodevisits{c} / sum(nodevisits{c}(refstat(inchain(1)),inchain));
        nodevisits{c} = abs(nodevisits{c});
    end
end
if ~isempty(self.qn) %&& isprop(self.qn,'chains')
    if exist('nodevisits','var')
        self.qn.setChains(chains, visits, rt ,nodevisits);
    else
        self.qn.setChains(chains, visits, rt ,[]);
    end
end
end
