function state = parseTranState(fileArv, fileDep, nodePreload)
% STATE = PARSETRANSTATE(FILEARV, FILEDEP, NODEPRELOAD)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

load(fileArv,'jobArvClasses','jobArvTS','jobArvClassID');
load(fileDep,'jobDepClasses','jobDepTS','jobDepClassID');
%% compute joint state at station
nClasses = length(nodePreload);
state = [jobArvTS,zeros(length(jobArvTS),nClasses);
    jobDepTS,zeros(length(jobDepTS),nClasses)];
for i=1:size(jobArvTS,1)
    state(i,1+jobArvClassID(i))=+1;
end
for i=1:size(jobDepTS)
    state(length(jobArvTS)+i,1+jobDepClassID(i))=-1;
end
state = sortrows(state,1);
state = [0,nodePreload;state];
for j=2:(nClasses+1)
    state(:,j) = cumsum(state(:,j));%+nodePreload(j-1);
end
end
