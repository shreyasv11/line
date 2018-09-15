clear;
N = 30;
M = 3;
E = 4;
rate = ones(M,E); rate(M,1:E)=(1:E); rate(1,1:E)=(E:-1:1);
envRates = [0,1,0,0; 0,0,1,1; 1,0,0,1; 1,1,0,0]/2;
env = cell(E);
for e=1:E
    for h=1:E
        if envRates(e,h)==0
            env{e,h} = Exp(0);
        else
            env{e,h} = Cox2.fitMeanAndSCV(1/envRates(e,h),0.5);
        end
    end
end
K=1;
qn1 = example_randomEnvironment_genqn(rate(:,1),N);
qn2 = example_randomEnvironment_genqn(rate(:,2),N);
qn3 = example_randomEnvironment_genqn(rate(:,3),N);
qn4 = example_randomEnvironment_genqn(rate(:,4),N);
%%
fprintf(1,'The metasolver considers an environment with 4 stages and a queueing network with 3 stations.\n')
fprintf(1,'Every time the stage changes, the queueing network will modify the service rates of the stations.\n')


options = Solver.defaultOptions;
options.timespan = [0,Inf];
options.iter_max = 100;
options.iter_tol = 0.05;
options.method = 'default';

soptions = SolverFluid.defaultOptions;
soptions.timespan = [0,Inf];
soptions.verbose = 0;
models = {qn1, qn2, qn3, qn4};
renvSolver = SolverEnv(models, env, @(model) SolverFluid(model, soptions),options);
[QN,UN,TN] = renvSolver.getAvg()
