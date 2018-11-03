function addPerfIndex(self, perfIndex)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
switch perfIndex.type
	case {Perf.TranQLen, Perf.TranUtil, Perf.TranTput}
	self.perfIndex.Tran{end+1, 1} = perfIndex;
	otherwise
	self.perfIndex.Avg{end+1, 1} = perfIndex;	
end
end
