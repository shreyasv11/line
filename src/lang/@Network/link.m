function self = link(self, P)
% SELF = LINK(P)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

isReset = false;
if ~isempty(self.qn)
    %    warning('Network topology already instantiated. Calling resetNetwork automatically.');
    isReset = true;
    self.resetNetwork;
end
R = self.getNumberOfClasses;
M = self.getNumberOfNodes;

if ~iscell(P) && R>1
    error('Multiclass model: the linked routing matrix P must be a cell array, e.g., P=model.initRoutingMatrix; P{1}=P1; P{2}=P2.');
end

isLinearP = true;
for s=2:R
    for r=1:R
        if nnz(P{r,s})>0
            isLinearP = false;
        end
    end
end

for i=self.getDummys
    for r=1:R
        if iscell(P)
            if isLinearP
                P{r}(i,self.getSink) = 1.0;
            else
                P{r,r}(i,self.getSink) = 1.0;
            end
        else
            P(i,self.getSink) = 0.0;
        end
    end
end

% This block is to make sure that P = model.initRoutingMatrix; P{2} writes
% into P{2,2} rather than being interpreted as P{2,1}.
if isLinearP
    for r=2:R
        P{r,r} = P{r,1};
        P{r,1} = 0*P{r,1};
    end
end

% link virtual sinks automatically to sink
ispool = cellisa(self.nodes,'Sink');
if sum(ispool) > 1
    error('The model can have at most one sink node.');
end

if sum(cellisa(self.nodes,'Source')) > 1
    error('The model can have at most one source node.');
end


if ~iscell(P)
    if R>1
        newP = cell(1,R);
        for r=1:R
            newP{r} = P;
        end
        P = newP;
    else %R==1
        % single class
        for i=find(ispool)'
            P((i-1)*R+1:i*R,:)=0;
        end
        Pmat = P;
        P = cell(R,R);
        for r=1:R
            for s=1:R
                P{r,s} = zeros(M);
                for i=1:M
                    for j=1:M
                        P{r,s}(i,j) = Pmat((i-1)*R+r,(j-1)*R+s);
                    end
                end
            end
        end
    end
end

if numel(P) == R
    % 1 matrix per class
    for r=1:R
        for i=find(ispool)'
            P{r}((i-1)*R+1:i*R,:)=0;
        end
    end
    Pmat = P;
    P = cell(R,R);
    for r=1:R
        P{r,r} = Pmat{r};
        for s=setdiff(1:R,r)
            P{r,s} = zeros(M);
        end
    end
end



for r=1:R
    for s=1:R
        if isempty(P{r,s})
            P{r,s} = zeros(M);
        else
            for i=find(ispool)'
                P{r,s}(i,:)=0;
            end
        end
    end
end

%             for r=1:R
%                 Psum=cellsum({P{r,:}})*ones(M,1);
%                 if min(Psum)<1-1e-4
%                   error('Invalid routing probabilities (Node %d departures, switching from class %d).',minpos(Psum),r);
%                 end
%                 if max(Psum)>1+1e-4
%                   error(sprintf('Invalid routing probabilities (Node %d departures, switching from class %d).',maxpos(Psum),r));
%                 end
%             end


self.linkedP = P;
for i=1:M
    for j=1:M
        csMatrix{i,j} = zeros(R);
        for r=1:R
            for s=1:R
                csMatrix{i,j}(r,s) = P{r,s}(i,j);
            end
        end
    end
end

% As we will now create a CS for each link i->j,
% we now condition on the job going from node i to j
for i=1:M
    for j=1:M
        for r=1:R
            if sum(csMatrix{i,j}(r,:))>0
                csMatrix{i,j}(r,:)=csMatrix{i,j}(r,:)/sum(csMatrix{i,j}(r,:));
            else
                csMatrix{i,j}(r,r)=1.0;
            end
        end
    end
end

csid = zeros(M);
nodeNames = self.getNodeNames;
for i=1:M
    for j=1:M
        if ~isdiag(csMatrix{i,j})
            self.nodes{end+1} = ClassSwitch(self, sprintf('CS_%s_to_%s',nodeNames{i},nodeNames{j}),csMatrix{i,j});
            csid(i,j) = length(self.nodes);
        end
    end
end

Mplus = length(self.nodes); % number of nodes after addition of cs nodes

% resize matrices
for r=1:R
    for s=1:R
        P{r,s}((M+1):Mplus,(M+1):Mplus)=0;
    end
end

for i=1:M
    for j=1:M
        if csid(i,j)>0
            % re-route
            for r=1:R
                for s=1:R
                    P{r,r}(i,csid(i,j)) = P{r,r}(i,csid(i,j))+ P{r,s}(i,j);
                    P{r,s}(i,j) = 0;
                    P{s,s}(csid(i,j),j) = 1;
                end
            end
        end
    end
end

connected = zeros(Mplus);
for i=1:Mplus
    for j=1:Mplus
        for r=1:R
            if P{r,r}(i,j) > 0
                if connected(i,j) == 0
                    self.addLink(self.nodes{i}, self.nodes{j});
                    connected(i,j) = 1;
                end
                self.nodes{i}.setProbRouting(self.classes{r}, self.nodes{j}, P{r,r}(i,j));
            end
        end
    end
end

if isReset
    %%re-instate all of this if re-instating refreshChains
    %nodetypes = self.getNodeTypes();
    %wantVisits = true;
    %if any(nodetypes == NodeType.Cache)
    %    wantVisits = false;
    %end
    %self.refreshChains(self.qn.rates, wantVisits);
    self.refreshStruct; % without this exception with linkAndLog
end
end
