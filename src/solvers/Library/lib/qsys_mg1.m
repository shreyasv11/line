function W=qsys_mg1(lambda,mu,cs)
rho=lambda/mu;
Q = rho + rho^2/(2*(1-rho)) + lambda^2*cs^2/mu^2/(2*(1-rho));
W = Q/lambda;
end