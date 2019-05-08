function tranSysState = sampleSys(self, numSamples)
% TRANSYSSTATE = SAMPLESYS(NUMSAMPLES)
if exist('numsamples','var')
    warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
end

options = self.getOptions;
if exist('numSamples','var')
options.samples = numSamples;    
end
switch options.method
    case {'default','serial'}
        [~, tranSystemState, tranSync] = self.run(options);
        tranSysState = struct();
        tranSysState.handle = self.model.getStatefulNodes';
        tranSysState.t = tranSystemState{1};
        tranSysState.state = {tranSystemState{2:end}};
        tranSysState.event = tranSync;
        if size(tranSysState.state,1) > numSamples
            tranSysState.t = tranSystemState{1}(1:numSamples);
            tranSysState.state = tranSysState.state(1:numSamples,:);
            tranSysState.event = tranSysState.event(1:numSamples);
        end
        tranSysState.isaggregate = false;
    otherwise
        error('sampleSys is not available in SolverSSA with the chosen method.');
end
end