function W=qsys_gig1_approx_kimura(sigma,mu,ca,cs)
W=sigma*(ca^2+cs^2)/mu/(1-sigma)/(1+ca^2);
end