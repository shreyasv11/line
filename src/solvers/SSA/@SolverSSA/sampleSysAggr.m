function sysStateAggr = sampleSysAggr(self, numSamples)
% TRANSYSSTATEAGGR = sampleSysAggr(NUMSAMPLES)
options = self.getOptions;

if ~exist('numSamples','var')
    numSamples = options.samples;
end

switch options.method
    case {'default','serial'}
        options.samples = numSamples;
        options.force = true;
        [~, tranSystemState] = self.run(options);
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
sysStateAggr.t = [0; sysStateAggr.t(2:end)];
end