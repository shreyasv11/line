function V = ifthenelse(cond,res1,res2)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.  
if cond
    V(1:length(res1)) = res1;
else
    V(1:length(res2)) = res2;
end
end