function Tsim = run(self)
% TSIM = RUN(SELF)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

T0=tic;
options = self.getOptions;

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
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the %s solver.',mfilename);
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
end

if ~self.model.hasInitState
    self.model.initDefault;
end

self.maxSamples = options.samples;

switch options.method
    case {'jsim','default'}
        self.writeJSIM;
        cmd = ['java -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt sim "',self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg" -seed ',num2str(options.seed), ' --illegal-access=permit'];
        if options.verbose
            fprintf(1,'JMT Model: %s\n',[self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg']);
            fprintf(1,'JMT Command: %s\n',cmd);
        end
    otherwise
        fname = self.writeJMVA([self.getFilePath(),'jmva',filesep, self.getFileName(),'.jmva']);
        cmd = ['java -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt mva "',fname,'" -seed ',num2str(options.seed), ' --illegal-access=permit'];
        if options.verbose
            fprintf(1,'JMT Model: %s\n',[self.getFilePath(),'jmva',filesep, self.getFileName(), '.jmva']);
            fprintf(1,'JMT Command: %s\n',cmd);
        end
end
[~, result] = system(cmd);
Tsim = toc(T0);

%if options.verbose
%    fprintf(1,sprintf('JMT analysis completed in %.6f sec \n',Tsim));
%end

if ~options.keep
    switch options.method
        case {'jsim','default'}
            delete([self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg']);
        otherwise % covers all JMVA submethods
            delete([self.getFilePath(),'jmva',filesep, self.getFileName(), '.jmva']);
    end
end

self.getResults;
end
