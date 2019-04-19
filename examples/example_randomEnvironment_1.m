if ~isoctave(), clearvars -except exampleName; end 
N = 1;
M = 2;
E = 2;
rate = zeros(M,E); rate(M,1:E)=(1:E); rate(1,1:E)=(E:-1:1);
envRates = [0,1; 0.5,0.5];
env = cell(E);
for e=1:E
    for h=1:E
        if envRates(e,h)==0
            env{e,h} = Exp(0);
        else
            env{e,h} = Exp(envRates(e,h));
        end
    end
end
K=1;
qn1 = example_randomEnvironment_genqn(rate(:,1),N);
qn2 = example_randomEnvironment_genqn(rate(:,1),N);
%%
fprintf(1,'The metasolver considers an environment with 2 stages and a queueing network with 2 stations.\n')
fprintf(1,'Every time the stage changes, the queueing network will modify the service rates of the stations.\n')

%options.iter_tol = 1e-5;
options = Solver.defaultOptions;
options.timespan = [0,Inf];
options.iter_max = 100;
options.iter_tol = 0.01;
options.method = 'default';
options.verbose = true;

soptions = SolverFluid.defaultOptions;
soptions.timespan = [0,Inf];
soptions.verbose = false;
models = {qn1, qn2};
renvSolver = SolverEnv(models,env,@(model) SolverFluid(model, soptions),options);
[QN,UN,TN] = renvSolver.getAvg()
