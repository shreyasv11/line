function stationStateAggr = sampleAggr(self, node, numEvents)
% STATIONSTATEAGGR = SAMPLEAGGR(NODE, NUMEVENTS)

if ~exist('node','var')
    error('sampleAggr requires to specify a node.');
end
if ~exist('numEvents','var')
    numEvents = -1;
end

Q = self.model.getAvgQLenHandles();
% create a temp model
modelCopy = self.model.copy;
modelCopy.resetNetwork;

% determine the nodes to logs
isNodeClassLogged = false(modelCopy.getNumberOfNodes, modelCopy.getNumberOfClasses);
ind = self.model.getNodeIndex(node.getName);
for r=1:modelCopy.getNumberOfClasses
    isNodeClassLogged(ind,r) = true;
end
% apply logging to the copied model
Plinked = self.model.getLinkedRoutingMatrix();
isNodeLogged = max(isNodeClassLogged,[],2);
logpath = tempdir;
modelCopy.linkAndLog(Plinked, isNodeLogged, logpath);
% simulate the model copy and retrieve log data
solverjmt = SolverJMT(modelCopy, self.getOptions);
solverjmt.maxEvents = numEvents;
solverjmt.getAvg(); % log data
logData = SolverJMT.parseLogs(modelCopy, isNodeLogged, Metric.QLen);

% from here convert from nodes in logData to stations
qn = modelCopy.getStruct;
ind = self.model.getNodeIndex(node.getName);
isf = qn.nodeToStateful(ind);
t = [];
nir = cell(1,qn.nclasses);
for r=1:qn.nclasses
    if isempty(logData{ind,r})
        nir{r} = [];
    else
        [~,uniqTS] = unique(logData{ind,r}.t);
        if isNodeClassLogged(isf,r)
            if ~isempty(logData{ind,r})
                t = logData{ind,r}.t(uniqTS);
                t = [t(2:end);t(end)];
                nir{r} = logData{ind,r}.QLen(uniqTS);
            end
        end
    end
end
if isfinite(self.options.timespan(2))
    stopAt = find(t>self.options.timespan(2),1,'first');
    if ~isempty(stopAt) && stopAt>1
        t = t(1:(stopAt-1));
        for r=1:length(nir)
            nir{r} = nir{r}(1:(stopAt-1));
        end
    end
end
stationStateAggr = struct();
stationStateAggr.handle = node;
stationStateAggr.t = t;
stationStateAggr.state = cell2mat(nir);
stationStateAggr.isaggregate = true;
stationStateAggr.t = [0; stationStateAggr.t(1:end-1)];
end