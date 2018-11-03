function lme = logmeanexp(x)
    lme = logsumexp(x) - log(length(x));
end