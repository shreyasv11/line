function stationStateAggr = sampleAggr(self, node)
% STATIONSTATEAGGR = SAMPLEAGGR(NODE)

if ~exist('station','var')
    error('sampleAggr requires to specify a station.');
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
SolverJMT(modelCopy, self.getOptions).getAvg(); % log data
logData = SolverJMT.parseLogs(modelCopy, isNodeLogged, Metric.QLen);

% from here convert from nodes in logData to stations
qn = modelCopy.getStruct;
ist = self.model.getStationIndex(node.getName);
isf = qn.stationToStateful(ist);
t = [];
nir = cell(1,qn.nclasses);
for r=1:qn.nclasses
    if ~isempty(logData{isf,r})
        [~,uniqTS] = unique(logData{isf,r}.t);
        if isNodeClassLogged(isf,r)
            if ~isempty(logData{isf,r})
                t = logData{isf,r}.t(uniqTS);
                t = [t(2:end);t(end)];
                nir{r} = logData{isf,r}.QLen(uniqTS);
            end
        end
    else
        nir{r} = [];
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
stationStateAggr.aggregate = true;
end