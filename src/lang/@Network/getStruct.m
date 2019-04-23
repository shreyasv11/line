function qn = getStruct(self, wantState)
% QN = GETSTRUCT(SELF, WANTSTATE)

if isempty(self.qn)
    self.refreshStruct();
end
if nargin == 1 || wantState
    self.qn.state = self.getState;
end
qn = self.qn;
end
