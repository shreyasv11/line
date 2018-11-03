function [AvgSysChainTable, CT,XT] = getAvgSysTable(self,R,T)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

if nargin==1
    R = self.model.getAvgRespTHandles;
    T = self.model.getAvgTputHandles;
end
[SysRespT, SysTput] = getAvgSys(self,R,T);
SysRespT = SysRespT';
SysTput = SysTput';
ChainObj = self.model.getChains();
Chain = cellfun(@(c) c.name,ChainObj,'UniformOutput',false)';
for c=1:length(Chain)
    Classes{c,1} = ChainObj{c}.classnames;
end
CT = table(Chain, Classes, SysRespT);
XT = table(Chain, Classes, SysTput);
AvgSysChainTable = table(Chain,Classes, SysRespT, SysTput);
end
