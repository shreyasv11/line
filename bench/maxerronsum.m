function [M,nanM]=maxerronsum(approx, exact)
% M = MAXERRONSUM(approx, exact)
% Returns max absolute error relative over vector sum
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
M = max(abs(exact-approx))/sum(exact);
if nargout > 1
    nanM = nanmax(abs(exact-approx))/sumfinite(exact);
end
end