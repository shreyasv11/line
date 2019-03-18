function W=qsys_gm1(sigma,mu)
% sigma = Load at arrival instants (Laplace transform of the arrival
% process)
W=sigma/(1-sigma)/mu;
end