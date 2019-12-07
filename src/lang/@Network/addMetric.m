function addMetric(self, perfIndex)
% ADDMETRIC(PERFINDEX)

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
switch perfIndex.type
    case {Metric.TranQLen, Metric.TranUtil, Metric.TranTput, Metric.TranRespT}
        self.perfIndex.Tran{end+1, 1} = perfIndex;
    otherwise
        self.perfIndex.Avg{end+1, 1} = perfIndex;
end
end
