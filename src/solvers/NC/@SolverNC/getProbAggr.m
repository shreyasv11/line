function Pnir = getProbAggr(self, node, state_a)
% PNIR = GETPROBSTATEAGGR(NODE, STATE_A)

if ~exist('state_a','var')
    state_a = self.model.getState{self.model.getStatefulNodeIndex(node)};
end
T0 = tic;
qn = self.model.getStruct;
% now compute marginal probability
ist = self.model.getStationIndex(node);
qn.state{ist} = state_a;
[Pnir,lG] = solver_nc_marg(qn, self.options);
self.result.('solver') = self.getName();
self.result.Prob.logNormConstAggr = lG;
self.result.Prob.marginal = Pnir;
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(ist);
end