function stationStateAggr = sampleAggr(self, node)
% TRANNODESTATEAGGR = SAMPLEAGGR(NODE)
if ~exist('station','var')
    error('sampleAggr requires to specify a station.');
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
        stationStateAggr.aggregate = true;
    otherwise
        error('sampleAggr is not available in SolverSSA with the chosen method.');
end
end