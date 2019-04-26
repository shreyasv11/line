function networks = refreshLayers(self)
% NETWORKS = REFRESHLAYERS()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
isBuild = false;
deepUpdate = true;
self.updateEnsemble(isBuild, deepUpdate);
networks = self.ensemble;
end
