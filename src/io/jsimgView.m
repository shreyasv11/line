function jsimgView(filename)
% JSIMGVIEW(FILENAME)
% Open model in JSIMgraph

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
cmd = ['java  --illegal-access=permit -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
[status] = system(cmd);
if  status > 0
    cmd = ['java  -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimg "',filename,'"'];
    [status] = system(cmd);
    if status > 0
        rt = java.lang.Runtime.getRuntime();
        rt.exec(cmd);
    end
end
end
