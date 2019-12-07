function [rates,scv, mu,phi,phases,lt] = refreshService(self)
% [RATES,SCV, MU,PHI,PHASES] = REFRESHSERVICE()
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
[rates, scv] = self.refreshRates;
[ph,mu,phi,phases] = self.refreshServicePhases;
[lt] = self.refreshLST;
end
