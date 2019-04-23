function classprio = refreshPriorities(self)
	% CLASSPRIO = REFRESHPRIORITIES(SELF)	
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

K = self.getNumberOfClasses();
classprio = zeros(1,K);
for r=1:K
    classprio(r) = self.classes{r}.priority;
end
if ~isempty(self.qn)
    self.qn.setPrio(classprio);
end
end
