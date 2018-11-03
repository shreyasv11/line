function S = getStationServers(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

for i=1:self.getNumberOfStations()
    S(i,1) = self.stations{i}.numberOfServers;
end
end