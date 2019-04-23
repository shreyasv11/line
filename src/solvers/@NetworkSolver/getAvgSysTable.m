function [AvgSysChainTable, CT,XT] = getAvgSysTable(self,R,T)
% [AVGSYSCHAINTABLE, CT,XT] = GETAVGSYSTABLE(SELF,R,T)

% Return table of average system metrics
%
% Copyright (c) 2012-2019, Imperial College London
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
CT = Table(Chain, Classes, SysRespT);
XT = Table(Chain, Classes, SysTput);
AvgSysChainTable = Table(Chain,Classes, SysRespT, SysTput);
end
