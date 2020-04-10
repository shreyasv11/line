if ~isoctave(), clearvars -except exampleName; end
N = 1;
M = 2;

E = 2;
envModel = Env('MyEnv');
envName = {'Stage1', 'Stage2'};
envType = {Semantics.UP, Semantics.DOWN};

rate = zeros(M,E); rate(M,1:E)=(1:E); rate(1,1:E)=(E:-1:1);
envSubModel = {example_randomEnvironment_genqn(rate(:,1),N), example_randomEnvironment_genqn(rate(:,2),N)};
for e=1:E
    envModel.addStage(envName{e}, envType{e}, envSubModel{e});
end

envRates = [0,1; 0.5,0.5];
for e=1:E
    for h=1:E
        if envRates(e,h)>0
            envModel.addTransition(envName{e}, envName{h}, Exp(envRates(e,h)));
        end
    end
end

%
fprintf(1,'The metasolver considers an environment with 2 stages and a queueing network with 2 stations.\n')
fprintf(1,'Every time the stage changes, the queueing network will modify the service rates of the stations.\n')

%options.iter_tol = 1e-5;
options = Solver.defaultOptions;
options.timespan = [0,Inf];
options.iter_max = 0;
options.iter_tol = 0.01;
options.method = 'default';
options.verbose = true;

envModel.getStageTable

envSolver = SolverEnv(envModel,@(model) SolverCTMC(model,'force',true),options);
[Q,F] = envSolver.getGenerator();

