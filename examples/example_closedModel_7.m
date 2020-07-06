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
    
%    node{2}.setService(jobclass{1}, APH([0.7,0.2,0.1],[-1,0,1; 0,-2,1; 0,0,-3]));
    node{2}.setService(jobclass{1}, APH.fitMeanAndSCV(1,1/c));
    node{2}.setService(jobclass{2}, APH.fitMeanAndSCV(1,1));
    node{2}.setService(jobclass{3}, APH.fitMeanAndSCV(1,c));
    
    P = model.initRoutingMatrix;
    P{1} = Network.serialRouting(node{1},node{2});
    P{2} = Network.serialRouting(node{1},node{2});
    P{3} = Network.serialRouting(node{1},node{2});
    
    model.link(P);
    
    % This part illustrates the execution of different solvers
    jmt{c} = SolverJMT(model,'seed',23000,'samples',1e4,'verbose',true).getAvgTable.RespT;
    flu{c} = SolverFluid(model).getAvgTable.RespT;
    mva{c} = SolverMVA(model).getAvgTable.RespT;
    nc{c} = SolverNC(model).getAvgTable.RespT;
    catch
    end
end
%%
rt = cell2mat(jmt)'; plot(max(rt'),'k'); hold on;
rt = cell2mat(flu)'; plot(max(rt'),'g'); 
rt = cell2mat(mva)'; plot(max(rt'),'b'); 
rt = cell2mat(nc)'; plot(max(rt'),'r')