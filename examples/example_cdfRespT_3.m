model = Network('myModel');
node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS); node{2}.setNumServers(1);
node{3} = Queue(model, 'Queue2', SchedStrategy.FCFS); node{3}.setNumServers(1);
node{4} = Sink(model, 'Sink');
jobclass{1} = OpenClass(model, 'Class1', 0);
node{1}.setArrival(jobclass{1}, Cox2.fitMeanAndSCV(2.000000,1.000000));
node{2}.setService(jobclass{1}, Cox2.fitMeanAndSCV(1.000000,1.000000));
node{3}.setService(jobclass{1}, Cox2.fitMeanAndSCV(1.000000,1.000000));
jobclass{2} = OpenClass(model, 'Class2', 0);
node{1}.setArrival(jobclass{2}, Cox2.fitMeanAndSCV(2.000000,1.000000));
node{2}.setService(jobclass{2}, Cox2.fitMeanAndSCV(1.000000,1.000000));
node{3}.setService(jobclass{2}, Cox2.fitMeanAndSCV(1.000000,1.000000));
P = cell(2);
P{1,1} = [0 1 0 0;0 0 0 0;0 0 0 1;0 0 0 0];
P{1,2} = [0 0 0 0;0 0 1 0;0 0 0 0;0 0 0 0];
P{2,1} = [0 0 0 0;0 0 0 0;0 0 0 1;0 0 0 0];
P{2,2} = [0 1 0 0;0 0 1 0;0 0 0 0;0 0 0 0];
model.link(P);
RD = SolverFluid(model).getCdfRespT()

%
ctmcoptions = SolverCTMC.defaultOptions; ctmcoptions.cutoff = 3;
simoptions = Solver.defaultOptions; simoptions.seed = 23000;
solver = {};
solver{end+1} = SolverJMT(model, simoptions);
solver{end+1} = SolverSSA(model, simoptions);
solver{end+1} = SolverFluid(model);
solver{end+1} = SolverMVA(model);
solver{end+1} = SolverNC(model);
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());    
    AvgTable = solver{s}.getAvgTable()
end

cdfmodel = model.copy;
cdfmodel.resetNetwork;
logpath = [fileparts(mfilename('fullpath')),filesep,'example_cdfRespT_4_logs'];
isNodeLogged = true(1,cdfmodel.getNumberOfNodes); % log only the delay node
cdfmodel.linkAndLog(P, isNodeLogged, logpath);
logData = SolverJMT.parseLogs(cdfmodel);

%%
figure;
for i=2:model.getNumberOfStations
    subplot(2,2,2*(i-2)+1)
    if ~isempty(logData{i,1}.RespT)
    [F,X]=ecdf(logData{i,1}.RespT);
    semilogx(X,1-F);
    hold all;
    semilogx(RD{i,1}(:,2),1-RD{i,1}(:,1),'--')
    legend('jmt','fluid','Location','Best');
    title(['CCDF: Node ',num2str(i),', Class ',num2str(1),', ',node{i}.serviceProcess{1}.name, ' service']);
    end
    
    subplot(2,2,2*(i-2)+2)
    if ~isempty(logData{i,2}.RespT)
    [F,X]=ecdf(logData{i,2}.RespT);
    semilogx(X,1-F);
    hold all;
    semilogx(RD{i,2}(:,2),1-RD{i,2}(:,1),'--')
    legend('jmt','fluid','Location','Best');
    title(['CCDF: Node ',num2str(i),', Class ',num2str(2),', ',node{i}.serviceProcess{2}.name, ' service']);
    end
end
