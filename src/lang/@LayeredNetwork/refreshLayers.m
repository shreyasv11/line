function networks = refreshLayers(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
isBuild = false;
deepUpdate = true;
self.updateEnsemble(isBuild, deepUpdate);
networks = self.ensemble;
end