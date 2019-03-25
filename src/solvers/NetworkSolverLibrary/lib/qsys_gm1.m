function W=qsys_gm1(sigma,mu)
% sigma = Load at arrival instants (Laplace transform of the inter-arrival times)
W=1/(1-sigma)/mu;
end