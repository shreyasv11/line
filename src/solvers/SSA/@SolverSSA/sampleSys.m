function tranSysState = sampleSys(self, numSamples)
% TRANSYSSTATE = SAMPLESYS(NUMSAMPLES)
options = self.getOptions;
if exist('numSamples','var')
    options.samples = numSamples;
else
    numSamples = options.samples;
end
switch options.method
    case {'default','serial'}
        [~, tranSystemState, tranSync] = self.run(options);
        tranSysState = struct();
        tranSysState.handle = self.model.getStatefulNodes';
        tranSysState.t = tranSystemState{1};
        tranSysState.state = {tranSystemState{2:end}};
        tranSysState.event = tranSync;
        for i=1:size(tranSysState.state,2)
            if size(tranSysState.state{i},1) > numSamples
                tranSysState.t = tranSystemState(1:numSamples);
                tranSysState.state = tranSysState.state{i}(1:numSamples,:);
                tranSysState.event = tranSysState.event{i}(1:numSamples);
            end
        end
        tranSysState.isaggregate = false;
    otherwise
        error('sampleSys is not available in SolverSSA with the chosen method.');
end
end