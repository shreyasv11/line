function [Q, U, R, X]=solveBPMN(filename, extFilename, options)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

import BPMN.*;

if nargin < 3
    options = [];
end
[outputFolder, RT, RTrange, iter_max, solver, verbose] = parseOptions(options);
%% input files parsing
model = BPMN.parseXML_BPMN(filename, verbose);
% LINE identifies BPMN element by ID, whereas in LQN we use names. We force
% in BPMN that names and IDs are identical.
model = BPMN.replaceNamesWithIDs(model);
modelExt = BPMN.parseXML_BPMNextensions(extFilename, verbose);

if ~isempty(model) && ~isempty(modelExt)
    %% create lqn model from bpmn
    myLN = BPMN2LayeredNetwork(model, modelExt, verbose);
    
    %% obtain line performance model from lqn
    [qn, entryObj, entryGraphs, processors] = LQN2QN(myLN);
   
    %% solve
    %iter_max = 1000;
    options = Solver.defaultOptions;
    [Q, U, R, X, resEntry,RT_CDF, resSEFF_CDF] = QN_fluid_analysis(qn, entryObj, entryGraphs, processors, RT, RTrange, options);
    
    %% process and export results
    for i = 1:qn.nstations
        if strcmp(qn.sched{i},SchedStrategy.INF)
            meanRT = sum(R([1:i-1 i+1:qn.nstations],:),1);
            break;
        end
    end
    
    %% write results
    % write results to output file
    [inputFolder, name, ~] = fileparts(filename);
    shortName = [name, '.xml'];
    if isempty(outputFolder)
        outPath = fullfile(inputFolder, shortName);
        writeXMLresults(outPath, '', qn, U, X, meanRT, R, resEntry, RT_CDF, resSEFF_CDF, verbose );
    else
        outPath = fullfile(outputFolder, shortName);
        writeXMLresults(outPath, '', qn, U, X, meanRT, R, [], RT_CDF, [], verbose );
    end
elseif isempty(model)
    disp('BPMN Model could not be created');
elseif isempty(modelExt)
    disp('BPMN Extension Model could not be created');
end
end