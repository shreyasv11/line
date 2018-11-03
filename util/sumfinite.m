function s = sumfinite(v, dim)
v(~isfinite(v)) = 0; 
if nargin>1
s = sum(v,dim);
else
s = sum(v);
end