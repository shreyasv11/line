clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);

jobclass{1} = ClosedClass(model, 'Class1', 1, node{1}, 0);
node{1}.setService(jobclass{1}, Exp.fitMoments(1.0));
node{2}.setService(jobclass{1}, Exp.fitMoments(2.0));

jobclass{2} = ClosedClass(model, 'Class2', 3, node{1}, 0);
node{1}.setService(jobclass{2}, Erlang.fitMeanAndOrder(4.0,2));
node{2}.setService(jobclass{2}, HyperExp.fitMoments(5.0,30.0));

P = cell(2);
%P{1,1} = circul(2)/2;
%P{1,2} = circul(2)/2;
%P{2,1} = circul(2)/8;
%P{2,2} = circul(2)*7/8;
P{1,1} = circul(2);
P{1,2} = zeros(2);
P{2,1} = zeros(2);
P{2,2} = circul(2);

% model
model.linkNetwork(P);
RDfluid = SolverFluid(model).getCdfRespT()
jmtoptions = SolverJMT.defaultOptions; jmtoptions.samples = 1e5;
RDsim = SolverJMT(model, jmtoptions).getTranCdfRespT();

%%
figure;
for i=1:model.getNumberOfStations
    subplot(model.getNumberOfStations,2,2*(i-1)+1)
    semilogx(RDsim{i,1}(:,2),1-RDsim{i,1}(:,1),'r')
    hold all;
    semilogx(RDfluid{i,1}(:,2),1-RDfluid{i,1}(:,1),'--')
    legend('jmt-transient','fluid-steady','Location','Best');
    title(['Tail: Node ',num2str(i),', Class ',num2str(1),', ',node{i}.serviceProcess{1}.name, ' service']);
    
    subplot(model.getNumberOfStations,2,2*(i-1)+2)
    semilogx(RDsim{i,2}(:,2),1-RDsim{i,2}(:,1),'r')
    hold all;
    semilogx(RDfluid{i,2}(:,2),1-RDfluid{i,2}(:,1),'--')
    legend('jmt-transient','fluid-steady','Location','Best');
    title(['Tail: Node ',num2str(i),', Class ',num2str(2),', ',node{i}.serviceProcess{2}.name, ' service']);
end
