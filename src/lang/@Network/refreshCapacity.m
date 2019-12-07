function [capacity, classcap] = refreshCapacity(self)
% [CAPACITY, CLASSCAP] = REFRESHCAPACITY()

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
M = self.getNumberOfStations();
K = self.getNumberOfClasses();
% set zero buffers for classes that are disabled
classcap = Inf*ones(M,K);
capacity = zeros(M,1);
for i=1:M
    for r=1:K
        if isempty(self.qn.rates(i,r)) || self.qn.rates(i,r)==0 || any(~isfinite(self.qn.rates(i,r)))
            classcap(i,r) = 0;
        else
            c = find(self.qn.chains(:,r)); % chain of class r
            classcap(i,r) = sum(self.qn.njobs(find(self.qn.chains(c,:))));
            if self.stations{i}.classCap(r) >= 0
                classcap(i,r) = min(classcap(i,r), self.stations{i}.classCap(r));
            end
            if self.stations{i}.cap >= 0
                classcap(i,r) = min(classcap(i,r),self.stations{i}.cap);
            end
        end
    end
    capacity(i,1) = sum(classcap(i,:));
end
if ~isempty(self.qn) %&& isprop(self.qn,'cap')
    self.qn.setCapacity(capacity, classcap);
end
end
