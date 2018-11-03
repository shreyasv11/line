function ret = jsimRun(filename)
%runtime = java.lang.Runtime.getRuntime();
cmd = ['java -cp "',jmtGetPath,filesep,'JMT.jar" jmt.commandline.Jmt sim "',filename, '" --illegal-access=permit']
ret = system(cmd);
%runtime.exec(cmd);
end

