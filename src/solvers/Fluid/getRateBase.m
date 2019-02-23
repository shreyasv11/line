function [rateBase, eventIdx] = getRateBase(Phi,Mu,M, K, match, q_indices, P, Kic, strategy, all_jumps)
rateBase = zeros(size(all_jumps,2),1);
eventIdx = zeros(size(all_jumps,2),1);
rateIdx = 0;
for i = 1 : M   %state changes from departures in service phases 2...
    for c = 1:K
        if match(i,c)>0
            for j = 1 : M
                for l = 1:K
                    if P((i-1)*K+c,(j-1)*K+l) > 0
                        for k = 1 : Kic(i,c)
                            rateIdx = rateIdx + 1;
                            rateBase(rateIdx) = Phi{i,c}(k) * P((i-1)*K+c,(j-1)*K+l) * Mu{i,c}(k);
                            eventIdx(rateIdx) = q_indices(i,c) + k - 1;
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
                rateIdx = rateIdx + 1;
                rateBase(rateIdx) = (1-Phi{i,c}(k))*Mu{i,c}(k);
                eventIdx(rateIdx) = q_indices(i,c) + k - 1;
            end
        end
    end
end
end % getRateBase

