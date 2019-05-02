function Pr = getProbAggr(self, node, state_a)
% PR = GETPROBSTATEAGGR(NODE, STATE_A)

if ~exist('state_a','var')
    state_a = self.model.getState{self.model.getStationIndex(node)};
end
stationStateAggr = self.sampleAggr(node);
ist = self.model.getStationIndex(node);
rows = findrows(stationStateAggr{ist}.state, state_a);
t = stationStateAggr{ist}.t;
dt = [t(1);diff(t)];
Pr = sum(dt(rows))/sum(dt);
end