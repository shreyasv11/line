function [rates,scv, mu,phi,phases] = refreshService(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
[rates, scv] = self.refreshRates;
[mu,phi,phases] = self.refreshCoxService;
end