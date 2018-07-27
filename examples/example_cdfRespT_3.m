clear;
model = Network('model');

node{1} = DelayStation(model, 'Delay');
node{2} = QueueingStation(model, 'Queue1', SchedStrategy.PS);
node{3} = QueueingStation(model, 'Queue2', SchedStrategy.PS);

jobclass{1} = ClosedClass(model, 'ClosedClass1', 1, node{1}, 0);

jobclass{1}.completes = false;

node{1}.setService(jobclass{1}, Exp(1/1));
node{2}.setService(jobclass{1}, Exp(1/2));
node{3}.setService(jobclass{1}, Exp(1/2));

M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = circul(M);
model.linkNetwork(P);
%%
options = SolverFluid.defaultOptions;
options.iter_max = 100;
solver = SolverFluid(model, options);
AvgRespT = solver.getAvgRespT
solver = SolverFluid(model, options);
FC = solver.getCdfRespT();
%%
for i=1:model.getNumberOfStations
    for c=1:model.getNumberOfClasses
%        plot(FC{i,c}(:,2),FC{i,c}(:,1)); hold all;
        AvgRespTfromCDF(i,c) = diff(FC{i,c}(:,1))'*FC{i,c}(2:end,2); %mean
        PowerMoment2_R(i,c) = diff(FC{i,c}(:,1))'*(FC{i,c}(2:end,2).^2);
        Variance_R(i,c) = PowerMoment2_R(i,c)-AvgRespTfromCDF(i,c)^2; %variance
        SqCoeffOfVariationRespTfromCDF(i,c) = (Variance_R(i,c))/AvgRespTfromCDF(i,c)^2; %scv
    end
end
AvgRespTfromCDF
SqCoeffOfVariationRespTfromCDF