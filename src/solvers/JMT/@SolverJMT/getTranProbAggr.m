function [Pi_t, SSnode_a] = getTranProbAggr(self, node)
% [PI_T, SSNODE_A] = GETTRANPROBSTATEAGGR(NODE)
error('Method not implemented yet.')
options = self.getOptions;
initSeed = self.options.seed;
if isfield(options,'timespan')  && isfinite(options.timespan(2))
    qn = self.getStruct;
    tu = [];
    stateu = {};
    for it=1:options.iter_max
        self.options.seed = initSeed + it -1;
        TranSysStateAggr{it} = self.sampleSysAggr;
        tu = union(tu, TranSysStateAggr{it}.t);
    end
    for j=1:length(TranSysStateAggr{it}.state)
        for it=1:options.iter_max
            TranSysStateAggr{it}.state{j} = floor(interp1(TranSysStateAggr{it}.t, TranSysStateAggr{it}.state{j}, tu));
            
        end
    end
    
    %                self.options.seed = initSeed; % in case of interruption
    %                jnd = self.model.getNodeIndex(node);
    %                SSnode_a = SSa(:,(jnd-1)*qn.nclasses+1:jnd*qn.nclasses);
    %                Pi_t = [t, pi_t];
    SSnode_a = [];
    Pi_t = [];
else
    error('getTranProbAggr in SolverJMT requires to specify a finite timespan T, e.g., SolverJMT(model,''timespan'',[0,T]).');
end
end