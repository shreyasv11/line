function [AN] = getAvgArvRChain(self,A)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

qn = self.model.getStruct();
%if nargin == 1
%    [Q] = self.model.getAvgHandles();
%end
[ANclass] = self.getAvgArvR();

% compute average chain metrics
AN = zeros(qn.nstations, qn.nchains);
for c=1:qn.nchains
    inchain = find(qn.chains(c,:));
    for i=1:qn.nstations
        if ~isempty(ANclass)
            AN(i,c) = sum(ANclass(i,inchain));
        end
    end
end
end
