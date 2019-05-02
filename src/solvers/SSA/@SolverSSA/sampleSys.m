function tranSysState = sampleSys(self, numsamples)
% TRANSYSSTATE = SAMPLESYS(NUMSAMPLES)
if exist('numsamples','var')
    warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
end

options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
        tranSysState = struct();
        tranSysState.handle = self.model.getStatefulNodes';
        tranSysState.t = tranSystemState{1};
        tranSysState.state = {tranSystemState{2:end}};
        tranSysState.isaggregate = false;
    otherwise
        error('sampleSys is not available in SolverSSA with the chosen method.');
end
end