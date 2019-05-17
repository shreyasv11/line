if ~isoctave(), clearvars -except exampleName; end
scale = 1;
for c=2:2:20
    try
    model = Network('model');
    
    node{1} = Delay(model, 'Delay');
    node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
    node{2}.setNumberOfServers(scale);
    
    jobclass{1} = ClosedClass(model, 'Class1', 2*scale, node{1}, 0);
    jobclass{2} = ClosedClass(model, 'Class2', 2*scale, node{1}, 0);
    jobclass{3} = ClosedClass(model, 'Class3', 2*scale, node{1}, 0);
    
    node{1}.setService(jobclass{1}, Exp(1));
    node{1}.setService(jobclass{2}, Exp(1));
    node{1}.setService(jobclass{3}, Exp(1));
    
    node{2}.setService(jobclass{1}, Coxian.fitMeanAndSCV(1,1/c));
    node{2}.setService(jobclass{2}, Coxian.fitMeanAndSCV(1,1));
    node{2}.setService(jobclass{3}, Coxian.fitMeanAndSCV(1,c));
    
    P = model.initRoutingMatrix;
    P{1} = Network.serialRouting(node{1},node{2});
    P{2} = Network.serialRouting(node{1},node{2});
    P{3} = Network.serialRouting(node{1},node{2});
    
    model.link(P);
    
    % This part illustrates the execution of different solvers
    jt{c} = SolverJMT(model,'seed',23000,'samples',1e4,'verbose',true).getAvgTable.RespT;
    ft{c} = SolverFluid(model).getAvgTable.RespT;
    mt{c} = SolverMVA(model).getAvgTable.RespT;
    nt{c} = SolverNC(model,'exact').getAvgTable.RespT;
    catch
    end
end
%%
rt = cell2mat(jt)'; plot(max(rt'),'k'); hold on;
rt = cell2mat(ft)'; plot(max(rt'),'g'); 
rt = cell2mat(mt)'; plot(max(rt'),'b'); 
rt = cell2mat(nt)'; plot(max(rt'),'r')