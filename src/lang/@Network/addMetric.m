function addMetric(self, perfIndex)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
switch perfIndex.type
	case {Metric.TranQLen, Metric.TranUtil, Metric.TranTput}
	self.perfIndex.Tran{end+1, 1} = perfIndex;
	otherwise
	self.perfIndex.Avg{end+1, 1} = perfIndex;	
end
end
