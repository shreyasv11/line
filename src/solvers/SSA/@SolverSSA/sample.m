function sampleNodeState = sample(self, node, numsamples)
% TRANNODESTATE = SAMPLE(NODE)

if exist('numsamples','var')
    warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
end

options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
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