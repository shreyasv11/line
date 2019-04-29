function runtime = run(self)
% RUNTIME = RUN()
% Run the solver

T0=tic;
options = self.getOptions;
if ~self.supports(self.model)
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
end
Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    error('The exact method requires the model to have a product-form solution. This model does not have one. You can use the Network method hasProductFormSolution() to check in advance.');
end

[Q,U,R,T,C,X,lG,runtime] = solver_mva_analysis(qn, options);
self.setAvgResults(Q,U,R,T,C,X,runtime);
self.result.Prob.logNormConstAggr = lG;
end