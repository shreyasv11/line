function [runtime, tranSysState] = run(self)
% [RUNTIME, TRANSYSSTATE] = RUN()

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

qn = self.model.getStruct();

% TODO: add priors on initial state
qn.state = self.model.getState; % not used internally by SSA
qn.space = qn.state; % SSA progressively grows this cell array into the simulated state space

[Q,U,R,T,C,X,~, tranSysState] = solver_ssa_analysis(qn, options);

runtime=toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end