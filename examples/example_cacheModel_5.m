clear;
model = CacheNetwork('model');
n = 8;
m = [4];
h=length(m);
N = [1,1];
D11 = 1e-4; D12 = 1e-4;
D21 = 1; D22 = 1;
D31 = 10; D32 = 3;
D = [D11,D12; D21,D22; D31,D32];

mainDelay = DelayStation(model, 'MainDelay');
cacheNode = CacheRouter(model, 'Cache1', n, m, ReplacementPolicy.RAND);
hitDelay = QueueingStation(model,'HitQ',SchedStrategy.INF);
missDelay = QueueingStation(model,'MissQ',SchedStrategy.INF);

initClass1 = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
hitClass1 = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
missClass1 = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);

initClass2 = ClosedClass(model, 'InitClass2', N(2), mainDelay, 0);
hitClass2 = ClosedClass(model, 'HitClass2', 0, mainDelay, 0);
missClass2 = ClosedClass(model, 'MissClass2', 0, mainDelay, 0);

%RM1 = DiscreteDistr(repmat([0.9,0.1]/scale,1,scale));
%RM2 = DiscreteDistr(repmat([0.5,0.5]/scale,1,scale));
RM1 = Zipf(0.5,n);
RM2 = Zipf(1.0,n);
cacheNode.setReference(initClass1, RM1);
cacheNode.setReference(initClass2, RM2);

mainDelay.setService(initClass1, Exp.fitMean(D11));
hitDelay.setService(hitClass1, Exp.fitMean(D21));
missDelay.setService(missClass1, Exp.fitMean(D31));

mainDelay.setService(initClass2, Exp.fitMean(D12));
hitDelay.setService(hitClass2, Exp.fitMean(D22));
missDelay.setService(missClass2, Exp.fitMean(D32));

cacheNode.setHitClass(initClass1, hitClass1);
cacheNode.setMissClass(initClass1, missClass1);

cacheNode.setHitClass(initClass2, hitClass2);
cacheNode.setMissClass(initClass2, missClass2);

P = cellzeros(6,6,4,4);
P{initClass1, initClass1}(1,2)=1;
P{hitClass1, hitClass1}(2,3)=1;
P{hitClass1, initClass1}(3,1)=1;
P{missClass1, missClass1}(2,4)=1;
P{missClass1, initClass1}(4,1)=1;

P{initClass2, initClass2}(1,2)=1;
P{hitClass2, hitClass2}(2,3)=1;
P{hitClass2, initClass2}(3,1)=1;
P{missClass2, missClass2}(2,4)=1;
P{missClass2, initClass2}(4,1)=1;

model.linkNetwork(P);

%AvgTable = SolverCTMC(model,'keep',true).getAvgTable
AvgTable = SolverSSA(model,'samples',1e4,'verbose',2).getAvgTable

%%
u = 2;
kset=1:n;
R={};
r=ones(u,n,h);
for k=1:n
    for v=1:u
        R{v,k}=zeros(h);
        for l=2:(h+1)
            R{v,k}(l-1,l)=r(v,k,l-1);
            R{v,k}(l-1,l-1)=1-r(v,k,l-1);
            R{v,k}(h,h)=1;
        end
    end
end
%%
T11 = AvgTable.Tput(3); T21 =  AvgTable.Tput(5);
T12 = AvgTable.Tput(4); T22 =  AvgTable.Tput(6);
T = [T11,T12; T21,T22];
X = ones(size(T));
Emp{1} = RM1;
Emp{2} = RM2;
X_1 = X*1e3;
goon=true;
while goon
    for v=1:u
        Xtot(v) = sum(X(:,v));
        for k=kset
            for j=1:(h+1)
                lambda(v,k,j)=Emp{v}.getPmf(k)*Xtot(v);
            end
        end
    end
    [gamma,u,n,h] = mucache_gamma(lambda,R);
    [~,MU] = mucache_miss(gamma,m,lambda);
    %%
    pHit = 1-MU./Xtot';
    AvgTableNet = example_cacheModel_5_sub1(D,N,pHit);
    X(1,1) = AvgTableNet.Tput(3);
    X(1,2) = AvgTableNet.Tput(4);
    X(2,1) = AvgTableNet.Tput(5);
    X(2,2) = AvgTableNet.Tput(6);
    if norm(X-X_1)<1e-3
        goon=false;
    end
    X_1 = X;
end
X
T
norm(X-T)
    