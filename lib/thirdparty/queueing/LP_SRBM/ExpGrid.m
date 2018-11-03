function P = ExpGrid(d,n,mu);
% Generates an approximating grid using an exponential spacing according to
% mu
% imput:    - d (SRBM dimension)
%           - n (number of points on each coordinate)
%           - mu (exponential spacing vector)

% output    - P (approximating grid)
x(1,1) = 0;
for k=1:d
    for i = 2:n
        x(i,k) = -(log(1-(i-1)/n))/(mu(k));
    end
end
npoints = n^d;
for k=1:d
    aux = n^(d-k);
    for j = 1:npoints;
        P(j,k) = x(rem(floor((j-1)/aux(k)), n)+1,k);
    end    
end
