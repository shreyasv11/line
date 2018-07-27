%% run all examples
format compact
warning on backtrace
clc
fprintf(1,'<strong>This script runs all LINE examples.</strong>\n');
fprintf(1,'The current workspace will be cleared and figures will be closed. \n');
fprintf(1,'Please press a key to continue or CTRL-C to terminate.\n');
%pause; clc
clear;
close all;

%% LINE examples
fprintf(1,'<strong>Running example_closedModel_*</strong>\n');

fprintf(1,'Example: <strong>example_closedModel_1</strong>\n'); example_closedModel_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_closedModel_2</strong>\n'); example_closedModel_2; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_closedModel_3</strong>\n'); example_closedModel_3; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_feasibility_*</strong>\n');
fprintf(1,'Example: <strong>example_feasibility_1</strong>\n'); example_feasibility_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_initState_*</strong>\n');
fprintf(1,'Example: <strong>example_initState_1</strong>\n'); example_initState_1; fprintf(1,'Pausing...'); pause(3.0); try, close(handleFig); end; 
fprintf(1,'Example: <strong>example_initState_2</strong>\n'); example_initState_2; fprintf(1,'Pausing...'); pause(3.0); try, close(handleFig); end; 
%%
fprintf(1,'<strong>Running example_openModel_*</strong>\n');
fprintf(1,'Example: <strong>example_openModel_1</strong>\n'); example_openModel_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_mixedModel_*</strong>\n');
fprintf(1,'Example: <strong>example_mixedModel_1</strong>\n'); example_mixedModel_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_scheduling_*</strong>\n');
fprintf(1,'Example: <strong>example_scheduling_1</strong>\n'); example_scheduling_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_stateProbabilities</strong>\n');
fprintf(1,'Example: <strong>example_stateProbabilities_1</strong>\n'); example_stateProbabilities_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_stateProbabilities_2</strong>\n'); example_stateProbabilities_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_cdfRespT_*</strong>\n');
fprintf(1,'Example: <strong>example_cdfRespT_1</strong>\n'); example_cdfRespT_1; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end; 
fprintf(1,'Example: <strong>example_cdfRespT_2</strong>\n'); example_cdfRespT_2; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end; 
%%
fprintf(1,'<strong>Running example_randomEnvironment_*</strong>\n');
fprintf(1,'Example: <strong>example_randomEnvironment_1</strong>\n'); example_randomEnvironment_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_randomEnvironment_2</strong>\n'); example_randomEnvironment_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_layeredModel_*</strong>\n');
fprintf(1,'Example: <strong>example_layeredModel_1</strong>\n'); example_layeredModel_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_layeredModel_2</strong>\n'); example_layeredModel_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running example_syntax_*</strong>\n');
fprintf(1,'Example: <strong>example_syntax_1</strong>\n'); example_syntax_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_syntax_2</strong>\n'); example_syntax_2; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_syntax_3</strong>\n'); example_syntax_3; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>example_syntax_4</strong>\n'); example_syntax_4; 
%%
fprintf(1,'Examples completed.')
