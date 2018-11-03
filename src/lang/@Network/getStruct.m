function qn = getStruct(self, wantState)
if isempty(self.qn)
    self.refreshStruct();
end
if nargin == 1 || wantState 
    self.qn.state = self.getState;
end
qn = self.qn; 
end