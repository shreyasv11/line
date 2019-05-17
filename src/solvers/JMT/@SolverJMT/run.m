function Trun = run(self)
% TSIM = RUN()

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end

if ~isfield(options,'verbose')
    options.verbose = 0;
end

if ~isfield(options,'force')
    options.force = false;
end

if ~isfield(options,'keep')
    options.keep = false;
end

if ~self.supports(self.model)
    %    if options.verbose
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the JMT solver.');
    %    end
    %    runtime = toc(T0);
    %    return
end

if ~isfield(options,'samples')
    options.samples = 1e4; % default: this is the samples / measure, not the total number of simulation events, which can be much larger.
elseif options.samples < 5e3
    if ~strcmpi(options.method,'jmva.ls')
        warning('JMT requires at least 5000 samples for each metric, current value is %d. Setting the samples to 5000.', options.samples);
    end
    options.samples = 5e3;
end

if ~isfield(options,'verbose')
    options.verbose = 0;
end

if ~isfield(options,'keep')
    options.verbose = false;
end

if ~isfield(options,'seed')
    options.seed = randi([1,1e6]);
end
self.seed = options.seed;

if ~isfield(options,'timespan')
    options.timespan = [0,Inf];
else
    self.maxSimulatedTime = options.timespan(2);
end

if ~self.model.hasInitState
    self.model.initDefault;
end

self.maxSamples = options.samples;

switch options.method
    case {'jsim','default'}
        if isinf(options.timespan(2)) || ((options.timespan(2)) == (options.timespan(1)))
            self.writeJSIM;
            cmd = ['java -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt sim "',self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg" -seed ',num2str(options.seed), ' --illegal-access=permit'];
            if options.verbose
                fprintf(1,'JMT Model: %s\n',[self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg']);
                fprintf(1,'JMT Command: %s\n',cmd);
            end
            [~, result] = system(cmd);
            Trun = toc(T0);
            if ~options.keep
                delete([self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg']);
                
            end
            self.getResults;
        else
            options = self.getOptions;
            initSeed = self.options.seed;
            initTimeSpan = self.options.timespan;
            self.options.timespan(1) = self.options.timespan(2);
            if isfield(options,'timespan')  && isfinite(options.timespan(2))
                qn = self.getStruct;
                tu = [];
                stateu = {};
                for it=1:options.iter_max
                    self.options.seed = initSeed + it -1;
                    TranSysStateAggr{it} = self.sampleSysAggr;
                    tu = union(tu, TranSysStateAggr{it}.t);
                end
                QNt = cellzeros(qn.nstations,qn.nclasses,length(tu),2);
                M = qn.nstations;
                K = qn.nclasses;
                for j=1:M
                    for r=1:K
                        QNt{j,r}(:,2) = tu;
                        for it=1:options.iter_max
                            QNt{j,r}(:,1) = QNt{j,r}(:,1) + (1/options.iter_max) * floor(interp1(TranSysStateAggr{it}.t, TranSysStateAggr{it}.state{j}(:,r), tu));
                        end
                    end
                end
                Trun = toc(T0);
                UNt = [];
                RNt = [];
                TNt = [];
                CNt = [];
                XNt = [];
                self.setTranAvgResults(QNt,UNt,RNt,TNt,CNt,XNt,Trun);
                self.result.Tran.Avg.U = cell(M,K);
                self.result.Tran.Avg.T = cell(M,K);
                self.result.Tran.Avg.Q = QNt;
            end
            self.options.seed = initSeed;
            self.options.timespan = initTimeSpan;
            self.result.('solver') = self.getName();
            self.result.runtime = Trun;
        end
    case {'jmva','jmva.mva','jmva.recal','jmva.comom','jmva.chow','jmva.bs','jmva.aql','jmva.lin','jmva.dmlin','jmva.ls',...
           'jmt.jmva','jmt.jmva.mva','jmt.jmva.amva','jmt.jmva.recal','jmt.jmva.comom','jmt.jmva.chow','jmt.jmva.bs','jmt.jmva.aql','jmt.jmva.lin','jmt.jmva.dmlin','jmt.jmva.ls'}
        fname = self.writeJMVA([self.getFilePath(),'jmva',filesep, self.getFileName(),'.jmva']);
        cmd = ['java -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt mva "',fname,'" -seed ',num2str(options.seed), ' --illegal-access=permit'];
        if options.verbose
            fprintf(1,'JMT Model: %s\n',[self.getFilePath(),'jmva',filesep, self.getFileName(), '.jmva']);
            fprintf(1,'JMT Command: %s\n',cmd);
        end
        [~, result] = system(cmd);
        Trun = toc(T0);
        
        if ~options.keep
            delete([self.getFilePath(),'jmva',filesep, self.getFileName(), '.jmva']);
        end
        self.getResults;
    otherwise 
        error('This solver does not support the specified method.');
end
end
