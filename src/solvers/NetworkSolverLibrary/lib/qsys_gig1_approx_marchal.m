function W=qsys_gig1_approx_marchal(lambda,mu,ca,cs)
rho=lambda/mu;
Wmm1 = rho/(1-rho);
W = Wmm1*(1+cs^2)/2/mu*(ca+rho^2*cs^2)/(1+rho^2*cs^2)+1/mu;
end