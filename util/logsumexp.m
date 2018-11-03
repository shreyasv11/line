function lse = logsumexp(x)
xstar = max(x);
lse = xstar + log(sum(exp(x-xstar)));
end