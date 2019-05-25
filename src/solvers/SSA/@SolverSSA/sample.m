function sampleNodeState = sample(self, node, numSamples)
% TRANNODESTATE = SAMPLE(NODE)

options = self.getOptions;
if exist('numSamples','var')
    options.samples = numSamples;
else
    numSamples = options.samples;
end
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run(options);
        isf = self.model.getStatefulNodeIndex(node);       
        sampleNodeState = struct();
        sampleNodeState.handle = node;
        sampleNodeState.t = tranSystemState{1};
        sampleNodeState.state = tranSystemState{1+isf};
        sampleNodeState.isaggregate = false;
    otherwise
        error('sample is not available in SolverSSA with the chosen method.');
end
end