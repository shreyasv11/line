function runtime = run(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end

if ~self.supports(self.model)
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the solver.');
end
Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    error('The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end

[Q,U,R,T,C,X,lG,runtime] = solver_mva_analysis(qn, options);
self.setAvgResults(Q,U,R,T,C,X,runtime);
self.result.Prob.logNormConstAggr = lG;
end