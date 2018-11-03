[Q,U,R,T] = model.getAvgHandles();
options.keep = false;
options.verbose = 1;
options.cutoff = 12;
options.seed = 23000-1;
options.samples = 1e4;
optionsjmt = options; optionsjmt.samples = 1e4;
solver = cell(1,5);
% This part illustrates the execution of different solvers
%solver{1} = SolverCTMC(model,options);
%solver{2} = SolverJMT(model,optionsjmt);
%solver{3} = SolverFluid(model,options);
solver{4} = SolverMVA(model,options);
%solver{5} = SolverSSA(model,options);
for s=1:length(solver)
    if ~isempty(solver{s})
        [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
        [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
        [CN{s},XN{s}] = solver{s}.getAvgSys();
    end
end
