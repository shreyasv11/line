clear QN UN RN TN QNc UNc RNc TNc CN XN
overwrite = false; % set to true to regenerate unit tests
run(testName);
model.initDefault;
solver = {};
% This part illustrates the savedecution of different solvers
solver{1} = SolverCTMC(model,'seed',23000,'cutoff',8);
solver{2} = SolverJMT(model,'seed',23000,'samples',1e6);
solver{3} = SolverFluid(model,'seed',23000,'tol',1e-8);
solver{4} = SolverMVA(model,'seed',23000);
solver{5} = SolverNC(model,'seed',23000,'samples',1e6);
solver{6} = SolverSSA(model,'seed',23000,'samples',1e5);
for s=1:length(solver)
    if ~isempty(solver{s})
        [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
        [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
        [CN{s},XN{s}] = solver{s}.getAvgSys();
    end
end
cwd = fileparts(mfilename('fullpath'));
if ~exist([testName,'.mat'],'file') || overwrite
    % if toleval data is not available, run the missing solvers and save
    for s=1:length(solver)
        if isempty(solver{s})
            if s==1, solver{1} = SolverCTMC(model,options); end
            if s==2, solver{2} = SolverJMT(model,optionsjmt); end
            if s==3, solver{3} = SolverFluid(model,options); end
            if s==4, solver{4} = SolverMVA(model,options); end
            if s==5, solver{5} = SolverNC(model,options); end
            if s==6, solver{6} = SolverSSA(model,options); end
        end
        if ~isempty(solver{s})
            [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
            [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
            [CN{s},XN{s}] = solver{s}.getAvgSys();
        end
    end
    Qsaved=QN; Usaved=UN; Rsaved=RN; Tsaved=TN;
    Qcsaved=QNc; Ucsaved=UNc; Rcsaved=RNc; Tcsaved=TNc;
    Csaved=CN; Xsaved=XN;
    save(fullfile(cwd,'toleval',[testName,'.mat']),'Qsaved','Usaved','Rsaved','Tsaved','Qcsaved','Ucsaved','Rcsaved','Tcsaved','Csaved','Xsaved');
else %else load toleval data
    load([testName,'.mat']);
end
tolEval(testName)