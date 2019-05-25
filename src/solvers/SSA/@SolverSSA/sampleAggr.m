function stationStateAggr = sampleAggr(self, node, numSamples)
% TRANNODESTATEAGGR = SAMPLEAGGR(NODE, NUMSAMPLES)
if ~exist('node','var')
    error('sampleAggr requires to specify a station.');
end

%if exist('numsamples','var')
    %warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
%end

options = self.getOptions;
switch options.method
    case {'default','serial'}
        options.samples = numSamples;
        options.force = true;
        [~, tranSystemState] = self.run(options);
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
stationStateAggr.t = [0; stationStateAggr.t(2:end)];
end