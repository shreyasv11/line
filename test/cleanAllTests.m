pd = pwd;
cwd = fileparts(mfilename('fullpath'));
cd(fullfile(cwd,'regression'))
delete *.mat
cd(cwd);
cd(pwd);
