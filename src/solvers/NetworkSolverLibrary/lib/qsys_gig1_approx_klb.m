function W=qsys_gig1_approx_klb(lambda,mu,ca,cs)
% W=QSYS_GIG1_APPROX_KLB(LAMBDA,MU,CA,CS)

% kramer-langenbach-belz formula
rho=lambda/mu;
if ca<=1
    g=exp(-2*(1-rho)*(1-ca^2)^2/(3*rho*(ca^2+cs^2)));
else
    g=exp(-(1-rho)*(ca^2-1)/(ca^2+4*cs^2));
end
W=(rho/(1-rho))/mu*((cs^2+ca^2)/2)*g+1/mu;
end
