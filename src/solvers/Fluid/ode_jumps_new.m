function jumps = ode_jumps_new(M, K, match, q_indices, P, Kic, strategy)
% JUMPS = ODE_JUMPS_NEW(M, K, MATCH, Q_INDICES, P, KIC, STRATEGY)

jumps = []; %returns state changes triggered by all the events
for i = 1 : M   %state changes from departures in service phases 2...
    for c = 1:K
        if match(i,c)>0
            xic = q_indices(i,c); % index of  x_ic
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0
                        xjl = q_indices(j,l); % index of x_jl
                        for k = 1 : Kic(i,c)
                            for kj = 1 : Kic(j,l)
                                jump = zeros( sum(sum(Kic)), 1 );
                                jump(xic+k-1) = jump(xic+k-1) - 1; %type c in stat i completes service
                                jump(xjl+kj-1) = jump(xjl+kj-1) + 1; %type c job starts in stat j
                                jumps = [jumps jump;];
                            end
                        end
                    end
                end
            end
        end
    end
end
for i = 1 : M   %state changes from "next service phase" transition in phases 2...
    for c = 1:K
        if match(i,c)>0
            xic = q_indices(i,c);
            for k = 1 : (Kic(i,c) - 1)
                for kp = (k+1):Kic(i,c)
                    jump = zeros( sum(sum(Kic)), 1 );
                    jump(xic+k-1) = jump(xic+k-1) - 1;
                    jump(xic+kp-1) = jump(xic+kp-1) + 1;
                    jumps = [jumps jump;];
                end
            end
        end
    end
end
end % ode_jumps_new()
