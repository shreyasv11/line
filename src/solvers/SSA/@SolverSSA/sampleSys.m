function tranSysState = sampleSys(self)
% TRANSYSSTATE = GETTRANSYSSTATE()

options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
        tranSysState = struct();
        tranSysState.handle = self.model.getStatefulNodes';
        tranSysState.t = tranSystemState{1};
        tranSysState.state = {tranSystemState{2:end}};
        tranSysState.aggregate = false;
    otherwise
        error('sampleSys is not available in SolverSSA with the chosen method.');
end
end