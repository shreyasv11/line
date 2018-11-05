function jsimwView(filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt jsimw "',which(filename),'"  --illegal-access=permit'];
%system(cmd);
rt = java.lang.Runtime.getRuntime();
rt.exec(cmd);
end