function [pos,f] = probchoose(p)
% pos = probchoose(p)
% Choose an element according to probability vector p
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

f = cumsum(p);
r = rand;
pos = maxpos(r<=f);
end