function [runtime, tranSysState, tranSync] = run(self, options)
% [RUNTIME, TRANSYSSTATE] = RUN()

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end

if ~self.supports(self.model)
    %                if options.verbose
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the solver.');
    %                end
    %                runtime = toc(T0);
    %                return
end

Solver.resetRandomGeneratorSeed(options.seed);

qn = self.model.getStruct();

% TODO: add priors on initial state
qn.state = self.model.getState; % not used internally by SSA
qn.space = qn.state; % SSA progressively grows this cell array into the simulated state space

[Q,U,R,T,C,X,~, tranSysState, tranSync] = solver_ssa_analysis(qn, options);

runtime = toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end