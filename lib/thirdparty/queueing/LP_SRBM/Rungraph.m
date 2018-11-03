function [EM P pd vd] = Rungraph(n,m,d,G,M,R,k);
% This routine runs the approximating algorithm, compute moment
% estimations and graphs marginal distributions

% imput:  - n (state space approximation parameter, number of
%           points on the approximating grid for each coordinate)
%         - m (functional space approximation parameter, degree of
%           polynomials on set of basis functions)
%         - d (dimension of the SRBM)
%         - G (Covariance matrix for SRBM)
%         - R (Reflextion matrix for SRBM)
%         - M (Drift vector for SRBM)
%         - k (degree of moment estimations)

% output - P (set of points on the approximating grid)
%        - EM (approx. moments)
%        - EM(i,j) approximates i-th moment on j-th coordinate        
%        - pd (interior stationary distribution for SRBM)
%        - vd (boundary stationary distribution for SRBM)

% Assume skew symmetric condition to construct approximating grid
mu = -2*inv(R)*M;

[P pd vd u exitflag K] = Alg(n,d,m,G,M,R,mu);   % running the algorihtm
EM = moments(pd,P,k,d);                         % computing moment estimates
[z epx] = ETRBM(P,pd,d,n);  %computing the marginals form the optimization output
spx      = SETRBM(epx,d);   %smoothing the marginals 
% ploting marginals densities
for i=1:d
    subplot(1,d,i), plot(z(:,i),spx(:,i),'b','LineWidth',1.5);

    tt = i;
    title(['Density for x_' int2str(i)]);
    xlabel(['x_' int2str(i)] );
end