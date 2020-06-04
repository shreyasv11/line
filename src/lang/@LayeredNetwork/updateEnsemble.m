function self = updateEnsemble(self, isBuild, deepUpdate)
% SELF = UPDATEENSEMBLE(ISBUILD, DEEPUPDATE)

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.

if isBuild
    self = self.buildEnsemble();
else
    self = self.refreshEnsemble(deepUpdate);
end

end
