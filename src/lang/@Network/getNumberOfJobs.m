function N = getNumberOfJobs(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

K = self.getNumberOfClasses();
N = zeros(K,1); % changed later
for k=1:K
    switch self.classes{k}.type
        case 'closed'
            N(k) = self.classes{k}.population;
        case 'open'
            N(k) = Inf;
    end
end
end
