function ensemble = getEnsemble(self)
if isempty(self.ensemble)
    self.updateEnsemble(true);
end
ensemble = self.ensemble;
end