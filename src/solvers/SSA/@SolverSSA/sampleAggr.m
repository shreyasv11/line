function stationStateAggr = sampleAggr(self, node, numsamples)
% TRANNODESTATEAGGR = SAMPLEAGGR(NODE)
if ~exist('station','var')
    error('sampleAggr requires to specify a station.');
end

if exist('numsamples','var')
    warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
end

options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
        qn = self.model.getStruct;
        isf = self.model.getStatefulNodeIndex(node);
        [~,nir]=State.toMarginal(qn,qn.statefulToNode(isf),tranSystemState{1+isf});
        stationStateAggr = struct();
        stationStateAggr.handle = node;
        stationStateAggr.t = tranSystemState{1};
        stationStateAggr.state = nir;
        stationStateAggr.isaggregate = true;
    otherwise
        error('sampleAggr is not available in SolverSSA with the chosen method.');
end
end