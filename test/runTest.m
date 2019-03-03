clear QN UN RN TN QNc UNc RNc TNc CN XN
w = warning;
warning off
overwrite = true; % set to true to regenerate unit tests

run(testName);
model.initDefault;
nclasses = model.getNumberOfClasses;
options = Solver.defaultOptions;
options.keep = false;
options.verbose = 1;
options.seed = 23000;
options.samples = 1e4;
%options.force = true;
switch testName
    case {'test_OQN_1','test_OQN_Cox_1','test_OQN_Cox_CS_1','test_OQN_DM1','test_OQN_ErM1','test_OQN_ErM1multi','test_OQN_HyM1','test_OQN_MM1','test_OQN_MM5'}
        options.cutoff = 11;
    case {'test_OQN_JMT_1','test_OQN_JMT_2','test_OQN_JMT_4','test_OQN_JMT_5','test_OQN_JMT_6','test_OQN_JMT_7','test_OQN_JMT_8','test_OQN_JMT_9',...
          'test_OQN_JMT_10','test_OQN_JMT_11','test_OQN_JMT_12','test_OQN_JMT_13','test_OQN_JMT_14_sparse_fcfs','test_OQN_JMT_14_sparse_ps','test_OQN_JMT_14_sparse_rand'}
        options.cutoff = 2;
    case {'test_OQN_JMT_3'}
        options.cutoff = 8;
        options.seed = 23001;
    case {'test_JMT2LINE_mixedqn'}
        options.cutoff = 1;
    otherwise
        options.cutoff = 2;
        options.force = false;
end
optionsjmt = options; optionsjmt.samples = 1e5;
optionsnc = options; optionsnc.samples = 1e6;

solver = {};
% This part illustrates the savedecution of different solvers
solver{1} = SolverCTMC(model,options);
%solver{2} = SolverJMT(model,optionsjmt);
solver{3} = SolverFluid(model,options);
solver{4} = SolverMVA(model,options);
solver{5} = SolverNC(model,optionsnc);
solver{6} = SolverSSA(model,options);
for s=1:length(solver)
    if ~isempty(solver{s})
        [QN{s},UN{s},RN{s},TN{s}] = solver{s}.getAvg();
        [QNc{s},UNc{s},RNc{s},TNc{s}] = solver{s}.getAvgChain();
        [CN{s},XN{s}] = solver{s}.getAvgSys();
    end
end
cwd = fileparts(mfilename('fullpath'));
if ~exist([testName,'.mat'],'file') || overwrite
    % if regression data is not available, run the missing solvers and save
    for s=1:length(solver)
        if isempty(solver{s})
            if s==1, solver{1} = SolverCTMC(model,options); end
            if s==2, solver{2} = SolverJMT(model,optionsjmt); end
            if s==3, solver{3} = SolverFluid(model,options); end
            if s==4, solver{4} = SolverMVA(model,options); end
            if s==5, solver{5} = SolverNC(model,optionsnc); end
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
    save(fullfile(cwd,'regression',[testName,'.mat']),'Qsaved','Usaved','Rsaved','Tsaved','Qcsaved','Ucsaved','Rcsaved','Tcsaved','Csaved','Xsaved');
else %else load regression data
    load([testName,'.mat']);
end

%TOL=2.5e-2; % 2.5-percent tolerance
TOL=1e-2; % 1-percent tolerance
for s=1:length(solver)
    if ~isempty(solver{s})
        if ~isempty(QN{s})
            try
                assert(max(max(abs(QN{s}-Qsaved{s})))<TOL,sprintf('%s changed on QN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(QN{s}),mat2str(Qsaved{s}),mat2str(Qsaved{2}))
                continue
            end
            try
                assert(max(max(abs(UN{s}-Usaved{s})))<TOL,sprintf('%s changed on UN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(UN{s}),mat2str(Usaved{s}),mat2str(Usaved{2}))
                continue
            end
            try
                assert(max(max(abs(RN{s}-Rsaved{s})))<TOL,sprintf('%s changed on RN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(RN{s}),mat2str(Rsaved{s}),mat2str(Rsaved{2}))
                continue
            end
            try
                assert(max(max(abs(TN{s}-Tsaved{s})))<TOL,sprintf('%s changed on TN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(TN{s}),mat2str(Tsaved{s}),mat2str(Tsaved{2}))
                continue
            end
            try
                assert(max(max(abs(QNc{s}-Qcsaved{s})))<TOL,sprintf('%s changed on QNc.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(QNc{s}),mat2str(Qcsaved{s}),mat2str(Qcsaved{2}))
                continue
            end
            try
                assert(max(max(abs(UNc{s}-Ucsaved{s})))<TOL,sprintf('%s changed on UNc.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(UNc{s}),mat2str(Ucsaved{s}),mat2str(Ucsaved{2}))
                continue
            end
            try
                assert(max(max(abs(RNc{s}-Rcsaved{s})))<TOL,sprintf('%s changed on RNc.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(RNc{s}),mat2str(Rcsaved{s}),mat2str(Rcsaved{2}))
                continue
            end
            try
                assert(max(max(abs(TNc{s}-Tcsaved{s})))<TOL,sprintf('%s changed on TNc.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(TNc{s}),mat2str(Tcsaved{s}),mat2str(Tcsaved{2}))
                continue
            end
            try
                assert(max(max(abs(CN{s}-Csaved{s})))<TOL,sprintf('%s changed on CN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(CN{s}),mat2str(Csaved{s}),mat2str(Csaved{2}))
                continue
            end
            try
                assert(max(max(abs(XN{s}-Xsaved{s})))<TOL,sprintf('%s changed on XN.',solver{s}.getName));
            catch me
                fprintf('Assertion failed for %s.\n%s\nNew: %s\nOld: %s\nSimEx: %s\n',solver{s}.name,me.message,mat2str(XN{s}),mat2str(Xsaved{s}),mat2str(Xsaved{2}))
                continue
            end
        else
            warning(['Solver ',solver{s}.name,' returned an empty result set. Skipping.']);
        end
    end
end
% tolEval(testName)

warning(w);
