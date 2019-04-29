function [lNormConst] = getProbNormConstAggr(self)
% [LNORMCONST] = GETPROBNORMCONST()

self.run();
lNormConst = self.result.Prob.logNormConstAggr;
end