function qn = example_randomEnvironment_genqn(rate, N)
%% qn1
qn = Network('qn1');

node{1} = DelayStation(qn, 'Queue1');
node{2} = QueueingStation(qn, 'Queue2', SchedStrategy.PS);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(qn, 'Class1', N, node{1}, 0);

node{1}.setService(jobclass{1}, Exp(rate(1)));
node{2}.setService(jobclass{1}, Exp(rate(2)));

K = 1;
P = cell(K,K);
P{1} = circul(length(node));

qn.linkNetwork(P);
end