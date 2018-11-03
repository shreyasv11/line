function jsimwView(filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
runtime = java.lang.Runtime.getRuntime();
cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',which(filename)];
%system(cmd);
runtime.exec(cmd);
end