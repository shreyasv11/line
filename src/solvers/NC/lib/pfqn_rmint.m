function logI = pfqn_rmint(L,N,Z)
nonzeroClasses = numel(N);
% repairmen integration
order = 15;
    % below we use a variable substitution u->u^2 as it seems to be
    % numerically better
    f= @(u) (2*u'.*exp(-(u.^2)').*prod((Z(nonzeroClasses)+L(nonzeroClasses).*repmat(u(:).^2,1,length(nonzeroClasses))).^N(nonzeroClasses),2))';
    p = 1-10^-order;
    exp1prctile = -log(1-p)/1; % cutoff for exponential term
    logI = log(integral(f,0,exp1prctile,'AbsTol',10^-order));
end