
% Getting started example from the LINE documentation
model = Network('stateTest2');

station{1} = DelayStation(model, 'Delay');
station{2} = Queue(model, 'Queue1', SchedStrategy.PS);
station{3} = Queue(model, 'Queue2', SchedStrategy.FCFS);

N(1) = 4; jobclass{1} = ClosedClass(model, 'A', N(1), station{1});
N(2) = 4; jobclass{2} = ClosedClass(model, 'B', N(2), station{1});

rate = [10,5; 20,0; 100,100];
for i=1:length(station)
    for r=1:length(jobclass)
        if i<3 % no for fcfs otherwise it's non-product-form
            phases=2;
            station{i}.setService(jobclass{r}, Erlang(rate(i,r)*phases,phases));
        else
            station{i}.setService(jobclass{r}, Exp(rate(i,r)));
        end
    end
end

P{1} = zeros(3); P{1}(1,1:3) = [0.1, 0.5, 0.4]; P{1}(2,[1,2])=[0.9,0.1]; P{1}(3,1) = 1.0; % type-A
P{2} = zeros(3); P{2}(1,3) = 1.0; P{2}(2:3,1) = 1.0; % type-B
V1=dtmc_solve(P{1}); V1=V1/V1(1);
V2=dtmc_solve(P{2}); V2=V2/V2(1);
model.link(P);
[M,R,C] = model.getSize();
qn = model.getStruct();


[Qlen,Util,Wait,Tput] = model.getAvgHandles();
options.verbose = 1;
options.keep = true;
options.samples = 1e4;

solver = SolverMVA(model,options);
[QN,UN,WN,TN] = solver.getAvg(Qlen,Util,Wait,Tput);
QN
UN
WN
TN
% for s1=1:size(Q,1)
% state=full(Q(s1,:));
% for t=find(state>0),
%     fprintf('from: %s\n to : %s\nrate: %d\n\n',num2str(SS(s1,:)),num2str(full(SS(t,:))),full(Q(s1,t)));
% end
% end
pi=ctmc_solve(full(Q));

if exist('pfqn_prob.m','file')
    D=1./rate.*[V1(:),V2(:)];
    D(isnan(D))=0;
    Z=D(1,:);
    D=D(2:M,:);
    pfqn_prob([0,0;0,0],D,N,Z)
    full1 = sum(SS(:,(phases*R+1):end),2)==0;
    sum(pi(full1))
end

