function jsimgView(filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
runtime = java.lang.Runtime.getRuntime();
cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
system(cmd)
%runtime.exec(cmd);
end