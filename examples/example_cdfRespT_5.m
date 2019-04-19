if ~isoctave(), clearvars -except exampleName; end 
figure;
label = {};
nJobs = [1,2,4,8,16];
for N = nJobs
    model = Network('model');
    
    node{1} = Delay(model, 'Delay');
    node{2} = Queue(model, 'Queue1', SchedStrategy.PS);
    node{3} = Queue(model, 'Queue2', SchedStrategy.PS);
    
    jobclass{1} = ClosedClass(model, 'Class1', N, node{1}, 0);
    
    jobclass{1}.completes = false;
    
    node{1}.setService(jobclass{1}, Exp(1/1));
    node{2}.setService(jobclass{1}, Exp(1/2));
    node{3}.setService(jobclass{1}, Exp(1/2));
    
    M = model.getNumberOfStations();
    K = model.getNumberOfClasses();
    
    P = circul(M);
    model.link(P);
    %%
    options = SolverFluid.defaultOptions;
    options.iter_max = 100;
    solver = SolverFluid(model, options);
    AvgRespT = solver.getAvgRespT
    FC = solver.getCdfRespT();
    %%
    for c=1:model.getNumberOfClasses
        for i=1:model.getNumberOfStations
            AvgRespTfromCDF(i,c) = diff(FC{i,c}(:,1))'*FC{i,c}(2:end,2); %mean
            PowerMoment2_R(i,c) = diff(FC{i,c}(:,1))'*(FC{i,c}(2:end,2).^2);
            Variance_R(i,c) = PowerMoment2_R(i,c)-AvgRespTfromCDF(i,c)^2; %variance
            SqCoeffOfVariationRespTfromCDF(i,c) = (Variance_R(i,c))/AvgRespTfromCDF(i,c)^2; %scv
        end
    end
    for i=2
        for c=1:model.getNumberOfClasses
            plot(FC{i,c}(:,2),FC{i,c}(:,1)); hold all;
        end
    end
    AvgRespTfromCDF
    %SqCoeffOfVariationRespTfromCDF
    label{end+1} = ['N=', num2str(N),' jobs'];
end
legend(label);
xlim([0,200])
title('Response time CDF at station 3 under increasing populations')
ylabel('Pr[RespT < t]')
xlabel('Response time t')
