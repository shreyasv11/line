function jsimgView(self, options)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

if ~self.supports(self.model)
    warning('This model is not supported by the %s solver. Quitting.',mfilename);
    runtime = toc(T0);
    return
end
if ~exist('options','var')
    options=Solver.defaultOptions();
end
if ~isfield(options,'samples')
    options.samples = 1e4; % default: this is the samples / measure, not the total number of simulation events, which can be much larger.
elseif options.samples< 5e3
    warning('JMT requires at least 5000 samples for each metric. Setting the samples to 5000.\n');
    options.samples = 5e3;
end
self.seed = options.seed;
self.maxSamples = options.samples;
writeJSIM(self);
%            if options.verbose
fprintf(1,'JMT Model: %s\n',[self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg']);
%            end
if isunix
    cmd = ['java -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg" -seed ',num2str(options.seed)];
    system(cmd);
else
    cmd = ['java --illegal-access=permit -cp "',self.getJMTJarPath(),filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',self.getFilePath(),'jsimg',filesep, self.getFileName(), '.jsimg" -seed ',num2str(options.seed)];
    rt = java.lang.Runtime.getRuntime();
    rt.exec(cmd);
end
end
