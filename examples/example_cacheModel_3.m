clear;
model = Network('model');
n = 3;
m = [1,1];
N = [1,1]
mainDelay = DelayStation(model, 'MainDelay');
cacheNode = Cache(model, 'Cache1', n, m, ReplacementPolicy.RAND);
hitDelay = DelayStation(model, 'HitDelay');
missDelay = DelayStation(model, 'MissDelay');

initClass1 = ClosedClass(model, 'InitClass1', N(1), mainDelay, 0);
hitClass1 = ClosedClass(model, 'HitClass1', 0, mainDelay, 0);
missClass1 = ClosedClass(model, 'MissClass1', 0, mainDelay, 0);

initClass2 = ClosedClass(model, 'InitClass2', N(2), mainDelay, 0);
hitClass2 = ClosedClass(model, 'HitClass2', 0, mainDelay, 0);
missClass2 = ClosedClass(model, 'MissClass2', 0, mainDelay, 0);

RM1 = DiscreteDistrib([0.5,0.5,0]);
RM2 = DiscreteDistrib([0,0.5,0.5]);
cacheNode.setReference(initClass1, RM1);
cacheNode.setReference(initClass2, RM2);

mainDelay.setService(initClass1, Exp.fitMean(1));
hitDelay.setService(hitClass1, Exp.fitMean(1));
missDelay.setService(missClass1, Exp.fitMean(2));

mainDelay.setService(initClass2, Exp.fitMean(1));
hitDelay.setService(hitClass2, Exp.fitMean(1));
missDelay.setService(missClass2, Exp.fitMean(2));

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

model.link(P);

AvgTable = SolverCTMC(model,'keep',true).getAvgTable
%SolverSSA(model).getAvgTable
%%
mset=[m];
X1 = AvgTable.Tput(1); X2 =  AvgTable.Tput(4);
Emp = DiscreteDistrib((X1/(X1+X2))*RM1.getPmf+(X2/(X1+X2))*RM2.getPmf)
for i=1:size(mset,1)
    clear lambda R
    m=mset(i,:);
    m=m(m>0);
    h=length(m);
    %u=2;
    u=1;
    for v=1:u
        kset=1:n;
        for k=kset
            for j=1:(h+1)
                %lambda(v,k,j)=(1/find(k==kset))^alpha(v);
                lambda(v,k,j)=Emp.getPmf(k);
            end
        end
    end
    R={};
    A=[];
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
    [gamma,u,n,h]=mucache_gamma(lambda,R);
    [M,MU,MI,pi0]=mucache_miss(gamma,m,lambda);
end
%%
OPENEX=1-pi0; OPENEX = OPENEX%/sum(EXACT)
%%
global InfGen;
global StateSpace;
SS = StateSpace;
Q = InfGen;
pi = ctmc_solve(Q);
offset = 2*model.getNumberOfClasses+1;
for j=1:n
    STEADY(j)=sum(pi(find(sum([SS(:,offset:offset+sum(m)-1)==j],2))));
end
STEADY = STEADY%/sum(STEADY)
%%
qn=model.getStruct;
global EventFilt;
D=EventFilt;
D1=zeros(size(D{1})); for a=1:length(D) if qn.sync{a}.active{1}.node==2 D1=D1+D{a}; end, end
MAPdep={Q-D1,D1};
pie = map_pie(MAPdep);
for j=1:n
    DEPMODEL(j)=sum(pie(find(sum([SS(:,offset:offset+sum(m)-1)==j],2))));
end
DEPMODEL = DEPMODEL%/sum(DEPMODEL)
%%
D1=zeros(size(D{1})); for a=1:length(D) if qn.sync{a}.passive{1}.node==2 D1=D1+D{a}; end, end
MAParv={Q-D1,D1};
pie = map_pie(MAParv);
for j=1:n
    ARVMODEL(j)=sum(pie(find(sum([SS(:,offset:offset+sum(m)-1)==j],2))));
end
ARVMODEL = ARVMODEL%/sum(ARVMODEL)

%SolverCTMC.printInfGen(Q,SS(:,offset:offset+sum(m)=1))
%SolverCTMC.printEventFilt(qn.sync,D,SS(:,offset:offset+sum(m)-1),2)