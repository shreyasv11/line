w = warning;
warning off;
cwd = fileparts(mfilename('fullpath'));
mkdir([cwd,'',filesep,'bin',filesep,'line',filesep,'src'])
mkdir([cwd,'',filesep,'bin',filesep,'line',filesep,'util'])
copyfile([cwd,'',filesep,'lib',filesep,''],[cwd,'',filesep,'bin',filesep,'line',filesep,'lib'])
delete([cwd,'',filesep,'bin',filesep,'line',filesep,'lib',filesep,'autocat',filesep,'*'])

disp('Generating binaries');
deploypcode([cwd,'',filesep,'src'],[cwd,'',filesep,'bin',filesep,'line',filesep,'src'], ...
    'updateOnly',true, 'flattenFileTree',false, 'includeHelp',true);
deploypcode([cwd,'',filesep,'util'],[cwd,'',filesep,'bin',filesep,'line',filesep,'util'], ...
    'updateOnly',true, 'flattenFileTree',false, 'includeHelp',true);
deploypcode([cwd,'',filesep,'lib',filesep,'autocat'],[cwd,'',filesep,'bin',filesep,'line',filesep,'lib',filesep,'autocat'], ...
    'updateOnly',true, 'flattenFileTree',false, 'includeHelp',true);
warning(w);

disp('Deleting files');
try
delete ../line-solver.git/src/*
end
try
delete ../line-solver.git/util/*
end
try
delete ../line-solver.git/examples/*
end
try
delete ../line-solver.git/examples/example_cdfRespT_4_logs/*
end
try
rmdir('../line-solver.git/bin/','s')
end
try
delete ../line-solver.git/doc/LINE.pdf
end

disp('Copying files');
%copyfile ./util/* ../line-solver.git/util/
%copyfile ./src/* ../line-solver.git/src/
copyfile ./bin/* ../line-solver.git/bin/
copyfile ./examples/* ../line-solver.git/examples/
copyfile ./doc/latex/LINE.pdf ../line-solver.git/doc/
%copyfile ./doc/markdown/*.md ../line-solver.wiki/
