function index = getIndexSourceStation(self)
% INDEX = GETINDEXSOURCESTATION()

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
index = find(cellisa(self.stations,'Source'));
end
