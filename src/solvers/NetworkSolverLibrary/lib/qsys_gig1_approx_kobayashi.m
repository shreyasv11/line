function W=qsys_gig1_approx_kobayashi(lambda,mu,ca,cs)
rho=lambda/mu;
rhohat=exp(-2*(1-rho)/(rho*(ca^2+cs^2/rho)));
W=rhohat/(1-rhohat)/lambda;
end