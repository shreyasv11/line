function W=qsys_gig1_approx_gelenbe(lambda,mu,ca,cs)
rho=lambda/mu;
W=(rho*ca^2+cs^2)/2/(1-rho)/lambda;
end