function sampleNodeState = sample(self, node)
% TRANNODESTATE = GETTRANSTATE(NODE)

options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
        isf = self.model.getStatefulNodeIndex(node);       
        sampleNodeState = struct();
        sampleNodeState.handle = node;
        sampleNodeState.t = tranSystemState{1};
        sampleNodeState.state = tranSystemState{1+isf};
        sampleNodeState.aggregate = false;
    otherwise
        error('sample is not available in SolverSSA with the chosen method.');
end
end