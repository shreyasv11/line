function jsimwView(filename)
% JSIMWVIEW(FILENAME)
% Open model in JSIMwiz

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
[path] = fileparts(filename);
if isempty(path)
    filename=[pwd,filesep,filename];
end
cmd = ['java  --illegal-access=permit -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
[status] = system(cmd);
if  status > 0
    cmd = ['java  -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',filename,'"'];
    [status] = system(cmd);
    if status > 0
        rt = java.lang.Runtime.getRuntime();
        rt.exec(cmd);
    end
end
end
