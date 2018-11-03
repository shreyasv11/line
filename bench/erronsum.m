function [M,nanM]=erronsum(approx, exact)
% M = ERRONSUM(approx, exact)
% Returns mean absolute error relative over vector sum
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
M = mean(abs(exact-approx))/sum(exact);
if nargout > 1
    nanM = nanmean(abs(exact-approx))/sumfinite(exact);
end
end