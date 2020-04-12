pd = pwd;
%logpath = tempdir;
userName = getenv('username');
userName(isspace(userName))=[];
filepath = [tempdir,'line.',userName,filesep];  

try
cwd = fullfile(filepath,'jsimg');
cd(cwd)
delete *.jsimg
delete *.jsimg-result.jsim
end

try
cwd = fullfile(filepath,'jmva');
cd(cwd)
delete *.jmva
delete *.jsimg-result.jsim
cd(pd)
end