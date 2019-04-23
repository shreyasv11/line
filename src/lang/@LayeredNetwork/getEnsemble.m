function ensemble = getEnsemble(self)
% ENSEMBLE = GETENSEMBLE(SELF)

if isempty(self.ensemble)
    self.updateEnsemble(true);
end
ensemble = self.ensemble;
end
