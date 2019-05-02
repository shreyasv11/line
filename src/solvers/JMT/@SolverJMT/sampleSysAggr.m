function sysStateAggr = sampleSysAggr(self, numEvents)
% SYSSTATEAGGR = SAMPLESYSAGGR(NUMEVENTS)

if ~exist('numEvents','var')
    numEvents = -1;
end

Q = self.model.getAvgQLenHandles();
statStateAggr = cell(self.model.getNumberOfStations,1);
% create a temp model
modelCopy = self.model.copy;
modelCopy.resetNetwork;
qn = self.model.getStruct;

% determine the nodes to logs
isNodeClassLogged = false(modelCopy.getNumberOfNodes, modelCopy.getNumberOfClasses);
for i= 1:modelCopy.getNumberOfStations
    ind = self.model.getNodeIndex(modelCopy.getStationNames{i});
    if qn.nodetype(ind) ~= NodeType.Source
        for r=1:modelCopy.getNumberOfClasses
            if ~Q{i,r}.disabled || nargin == 1
                isNodeClassLogged(ind,r) = true;
            else
                isNodeClassLogged(node,r) = true;
            end
        end
    end
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
for ist= 1:qn.nstations
    isf = qn.stationToStateful(ist);
    ind = qn.stationToNode(ist);
    t = [];
    nir = cell(1,qn.nclasses);
    if qn.nodetype(ind) == NodeType.Source
        nir{r} = [];
    else
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
    statStateAggr{ist} = struct();
    statStateAggr{ist}.handle = self.model.stations{ist};
    statStateAggr{ist}.t = t;
    statStateAggr{ist}.state = cell2mat(nir);
    statStateAggr{ist}.isaggregate = true;
end

tranSysStateAggr = cell(1,1+self.model.getNumberOfStations);

tranSysStateAggr{1} = []; % timestamps
for i=1:self.model.getNumberOfStations % stations
    tranSysStateAggr{1} = union(tranSysStateAggr{1}, statStateAggr{i}.t);
end

for i=1:self.model.getNumberOfStations % stations
    ind = qn.stationToNode(i);
    tranSysStateAggr{1+i} = [];
    [~,uniqTS] = unique(statStateAggr{i}.t);
    if qn.nodetype(ind) ~= NodeType.Source
        for j=1:self.model.getNumberOfClasses % classes
            % we floor the interpolation as we hold the last state
            if ~isempty(uniqTS)
                Qijt = floor(interp1(statStateAggr{i}.t(uniqTS), statStateAggr{i}.state(uniqTS,j), tranSysStateAggr{1}));
                if isnan(Qijt(end))
                    Qijt(end)=Qijt(end-1);
                end
                tranSysStateAggr{1+i} = [tranSysStateAggr{1+i}, Qijt];
            else
                Qijt = NaN*ones(length(tranSysStateAggr{1}),1);
                tranSysStateAggr{1+i} = [tranSysStateAggr{1+i}, Qijt];
            end
        end
    end
end
sysStateAggr = struct();
sysStateAggr.handle = self.model.stations';
sysStateAggr.t = tranSysStateAggr{1};
sysStateAggr.state = {tranSysStateAggr{2:end}};
sysStateAggr.isaggregate = true;
end