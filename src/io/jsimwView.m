function jsimwView(filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
if isunix
    cmd = ['java  -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
    system(cmd);
else
    cmd = ['java  --illegal-access=permit -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
    rt = java.lang.Runtime.getRuntime();
    rt.exec(cmd);
end
end