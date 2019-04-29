function [lNormConst] = getProbNormConstAggr(self)
% [LNORMCONST] = GETPROBNORMCONST()

if ~isempty(self.result)
    lNormConst = self.result.Prob.logNormConstAggr;
else
    optnc = self.options;
    optnc.method = 'exact';
    [~,~,~,~,~,~,lNormConst] = solver_mva_analysis(self.getStruct, optnc);
    self.result.Prob.logNormConstAggr = lNormConst;
end
end