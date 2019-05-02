function sysStateAggr = sampleSysAggr(self, NUMSAMPLES)
% TRANSYSSTATEAGGR = sampleSysAggr(NUMSAMPLES)
if exist('numsamples','var')
    warning('SolveSSA does not support the numsamples parameter, use instead the samples option upon instantiating the solver.');
end


options = self.getOptions;
switch options.method
    case {'default','serial'}
        [~, tranSystemState] = self.run;
        qn = self.model.getStruct;
        for ist=1:self.model.getNumberOfStations
            isf = qn.stationToStateful(ist);
            [~,nir]=State.toMarginal(qn,qn.stationToNode(ist),tranSystemState{1+isf});
            tranSystemState{1+ist} = nir;
        end
        sysStateAggr = struct();
        sysStateAggr.handle = self.model.stations';
        sysStateAggr.t = tranSystemState{1};
        sysStateAggr.state = {tranSystemState{2:end}};
        sysStateAggr.isaggregate = true;   
    otherwise
        error('sampleSys is not available in SolverSSA with the chosen method.');
end
end