function logData = parseLogs(model,isNodeLogged, metric)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

numOfResources = length(model.stations);
for i=1:numOfResources
    numOfResources = numOfResources - isa(model.stations{i},'Logger');
end
numOfClasses = length(model.classes);
logData = cell(numOfResources,numOfClasses);
for i=1:numOfResources
    if isNodeLogged(i)
        logFileArv = [model.getLogPath,sprintf('%s-Arv.csv',model.getNodeNames{i})];
        logFileDep = [model.getLogPath,sprintf('%s-Dep.csv',model.getNodeNames{i})];
        %% load arrival process
        if exist(logFileArv,'file') && exist(logFileDep,'file')
            %            logArv=readTable(logFileArv,'Delimiter',';','HeaderLines',1); % raw data
            
            %%
            % unclear if this part works fine if user has another local
            % since JMT might write with a different delimiter
            fid=fopen(logFileArv);
            logArv = textscan(fid, '%s%f%f%s%s%s', 'delimiter',';', 'headerlines',1);            
            fclose(fid);
            jobArvTS = logArv{2};
            jobArvID = logArv{3};
            jobArvClass = logArv{4};
            clear logArv;
            
            %%
            jobArvClasses = unique(jobArvClass);
            jobArvClassID = zeros(length(jobArvClass),1);
            for c=1:length(jobArvClasses)
                jobArvClassID(find(strcmp(jobArvClasses{c},jobArvClass))) = findstring(model.getClassNames,jobArvClasses{c});
                %                jobArvClassID(find(strcmp(jobArvClasses{c},jobArvClass)))=c;
            end
            logFileArvMat = [model.getLogPath,filesep,sprintf('%s-Arv.mat',model.getNodeNames{i})];
            save(logFileArvMat,'jobArvTS','jobArvID','jobArvClass','jobArvClasses','jobArvClassID');
            
            %% load departure process
            fid=fopen(logFileDep);
            logDep = textscan(fid, '%s%f%f%s%s%s', 'delimiter',';', 'headerlines',1);
            fclose(fid);
            jobDepTS = logDep{2};
            jobDepID = logDep{3};
            jobDepClass = logDep{4};
            clear logDep;
            
            %             jobDepTS = table2array(logDep(:,2));
            %             jobDepID = table2array(logDep(:,3));
            %             jobDepClass = table2cell(logDep(:,4));
            jobDepClasses = unique(jobDepClass);
            jobDepClassID = zeros(length(jobDepClass),1);
            for c=1:length(jobDepClasses)
                jobDepClassID(find(strcmp(jobDepClasses{c},jobDepClass))) = findstring(model.getClassNames,jobDepClasses{c});
                %                jobDepClassID(find(strcmp(jobDepClasses{c},jobDepClass)))=c;
            end
            logFileDepMat = [model.getLogPath,filesep,sprintf('%s-Dep.mat',model.getNodeNames{i})];
            save(logFileDepMat,'jobDepTS','jobDepID','jobDepClass','jobDepClasses','jobDepClassID');
            
            nodePreload = zeros(1,numOfClasses);
            for r=1:numOfClasses
                if strcmpi(model.classes{r}.reference.name,model.stations{i}.name)
                    switch model.classes{r}.type
                        case 'closed'
                            nodePreload(r) = model.classes{r}.population;
                    end
                end
            end
            
            switch metric
                case Perf.QLen
                    [nodeState{i}] = SolverJMT.parseTranState(logFileArvMat, logFileDepMat, nodePreload);
                    
                    %% save in default data structure
                    for r=1:numOfClasses %0:numOfClasses
                        logData{i,r} = struct();
                        logData{i,r}.t = nodeState{i}(:,1);
                        logData{i,r}.QLen = nodeState{i}(:,1+r);
                    end
                case Perf.RespT
                    [classResT, jobRespT, jobResTArvTS] = SolverJMT.parseTranRespT(logFileArvMat, logFileDepMat);
                    
                    for r=1:numOfClasses
                        logData{i,r} = struct();
                        if r <= size(classResT,2)
                            logData{i,r}.t = jobResTArvTS;
                            logData{i,r}.RespT = classResT{r};
                            %logData{i,r}.PassT = jobRespT;
                        else
                            logData{i,r}.t = [];
                            logData{i,r}.RespT = [];
                            %logData{i,r}.PassT = [];
                        end
                    end
            end
        end
    end
end
end

