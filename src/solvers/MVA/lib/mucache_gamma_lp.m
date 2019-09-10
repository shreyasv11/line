function [gamma,u,n,h]=mucache_gamma_lp(lambda,R)
% formerly mucache_gamma_tree_linearpath.m
u=size(lambda,1); % number of users
n=size(lambda,2); % number of items
h=size(lambda,3)-1; % number of lists

gamma=zeros(n,h);
for i = 1:n % for all items
    for j = 1:h % for all levels
        % compute gamma(i,j)
        Rvi = 0*R{1,i};
        for v=1:u
            Rvi = Rvi + R{v,i};
        end
        Gvi = digraph(Rvi); % we take the topology from stream v
        Pij = [Gvi.shortestpath(1,1+j)];
        if isempty(Pij)
            gamma(i,j)=0;
        else
            gamma(i,j)=1;
            for li = 2:length(Pij) % for all levels up to the current one
                y = 0;
                l_1 = Pij(li-1);
                l = Pij(li);
                for v = 1:u % for all streams
                    for t=1:l_1
                        y=y + lambda(v, i, t) * R{v,i}(t, l);
                    end
                end
                gamma(i,j)=gamma(i,j)*y;
            end
        end
    end
end

end