function runtime = run(self)
% RUNTIME = RUN()
% Run the solver

T0=tic;
options = self.getOptions;

if ~self.supports(self.model)
    %                if options.verbose
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
    %                end
    %                runtime = toc(T0);
    %                return
end

Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

[Q,U,R,T,C,X] = solver_mam_analysis(qn, options);

runtime=toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end