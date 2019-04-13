function [rateBase, eventIdx] = getRateBase(Phi, Mu, PH, M, K, match, q_indices, P, Kic, strategy, all_jumps)
rateBase = zeros(size(all_jumps,2),1);
eventIdx = zeros(size(all_jumps,2),1);
rateIdx = 0;

for i = 1 : M   %state changes from departures in service phases 2...
    for c = 1:K
        if match(i,c)>0
            for j = 1 : M
                for l = 1:K
                    pie = map_pie(PH{j,l});
                    if P((i-1)*K+c,(j-1)*K+l) > 0
                        for k = 1 : Kic(i,c)
                            for kj = 1 : Kic(j,l)
                                rateIdx = rateIdx + 1;
                                rateBase(rateIdx) = Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k) * pie(kj);
                                eventIdx(rateIdx) = q_indices(i,c) + k - 1;
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
            for k = 1 : (Kic(i,c) - 1)
                for kp = k+1 : Kic(i,c) % APH distribution
                    rateIdx = rateIdx + 1;
                    rateBase(rateIdx) = PH{i,c}{1}(k,kp);
                    eventIdx(rateIdx) = q_indices(i,c) + k - 1;
                end
            end
        end
    end
end

end % getRateBase

