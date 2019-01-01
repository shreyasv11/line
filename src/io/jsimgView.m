function jsimgView(filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
if isunix
    cmd = ['java  -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
    system(cmd);
else
    cmd = ['java  --illegal-access=permit -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
    rt = java.lang.Runtime.getRuntime();
    rt.exec(cmd);
end
end