function Wub=qsys_gig1_ubnd_kingman(lambda,mu,ca,cs)
% WUB=QSYS_GIG1_UBND_KINGMAN(LAMBDA,MU,CA,CS)

rho=lambda/mu;
Wub = rho/(1-rho)*(ca^2+cs^2)/2*(1/mu) + (1/mu);
end
