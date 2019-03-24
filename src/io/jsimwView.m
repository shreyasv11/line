function jsimwView(filename)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
cmd = ['java  --illegal-access=permit -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
%        rt = java.lang.Runtime.getRuntime();
%        rt.exec(cmd)
[status,result] = system(cmd);
if  status > 0
    cmd = ['java  -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
    system(cmd);
end
end