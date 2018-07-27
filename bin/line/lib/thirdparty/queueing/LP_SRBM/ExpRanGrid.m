function P = ExpRanGrid(d,n,mu)
    npoints(1) = n^d;
    npoints(2:d+1) =2*n;
    P = [];
    for k=1:d+1
        G = rand(npoints(k),d);
        A =[];
        for j=1:d
            A = [A  -log(G(:,j))./mu(j)];
        end
        if k>1
            A(:,k-1)=0;
        end
        P = [P;A];
    end