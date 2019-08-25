function model = gallery_cqn_multiclass(m,r)
model = Network('Multi-class CQN');
%% Block 1: nodes
node{1} = DelayStation(model, 'Delay 1');
for i=1:m
    node{1+i} = Queue(model, ['Queue ',num2str(i)], SchedStrategy.PS);
end
%% Block 2: classes
for s=1:r
    jobclass{s} = ClosedClass(model, ['Class',num2str(s)], 5, node{1}, 0);
end

for s=1:r
    node{1}.setService(jobclass{s}, Exp.fitMean(2.000000+s)); % (Delay 1,Class1)
    for i=1:m
        node{1+i}.setService(jobclass{s}, Exp.fitMean(1.000000+i+s)); % (Queue 1,Class1)
    end
end

%% Block 3: topology
P = model.initRoutingMatrix(); % initialize routing matrix
for s=1:r
    P{jobclass{s},jobclass{s}} = Network.serialRouting(node);
end
model.link(P);
end