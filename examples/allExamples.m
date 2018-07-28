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
fprintf(1,'Example: <strong>clear; example_closedModel_1</strong>\n'); 
fprintf(1,'This example illustrates the execution of different solvers on a basic closed model.\n')
clear; example_closedModel_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_closedModel_2</strong>\n'); 
fprintf('This example shows the execution of the solver on a 2-class 2-node class-switching model.')
clear; example_closedModel_2; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_closedModel_3</strong>\n'); 
fprintf(1,'This example shows the execution of the solver on a 3-class 2-chain 2-node model.')
fprintf(1,'Performance indexes by chain are calculated.')
clear; example_closedModel_3; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_feasibility_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_feasibility_1</strong>\n'); 
fprintf(1,'This example shows that LINE automatically checks if a solver is feasible for a given model.\n');
fprintf(1,'If not, an empty result set is returned.\n');
clear; example_feasibility_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_initState_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_initState_1</strong>\n'); 
fprintf(1,'This example shows the execution of the transient solver on a 2-class 2-node class-switching model.')
clear; example_initState_1; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end 
fprintf(1,'Example: <strong>clear; example_initState_2</strong>\n'); 
fprintf(1,'This example shows the execution of the transient solver on a 2-class 2-node class-switching model.')
clear; example_initState_2; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end
%%
fprintf(1,'<strong>Running clear; example_openModel_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_openModel_1</strong>\n'); 
clear; example_openModel_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_mixedModel_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_mixedModel_1</strong>\n'); 
clear; example_mixedModel_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_scheduling_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_scheduling_1</strong>\n'); 
clear; example_scheduling_1; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_stateProbabilities</strong>\n');
fprintf(1,'Example: <strong>clear; example_stateProbabilities_1</strong>\n'); 
clear; example_stateProbabilities_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_stateProbabilities_2</strong>\n'); 
clear; example_stateProbabilities_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_cdfRespT_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_cdfRespT_1</strong>\n'); 
clear; example_cdfRespT_1; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end; 
fprintf(1,'Example: <strong>clear; example_cdfRespT_2</strong>\n'); 
clear; example_cdfRespT_2; fprintf(1,'Pausing...'); pause(3.0); try close(handleFig); end; 
%%
fprintf(1,'<strong>Running clear; example_randomEnvironment_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_randomEnvironment_1</strong>\n'); 
clear; example_randomEnvironment_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_randomEnvironment_2</strong>\n'); 
clear; example_randomEnvironment_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_layeredModel_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_layeredModel_1</strong>\n'); 
clear; example_layeredModel_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_layeredModel_2</strong>\n'); 
clear; example_layeredModel_2; fprintf(1,'Pausing...'); pause(3.0); 
%%
fprintf(1,'<strong>Running clear; example_syntax_*</strong>\n');
fprintf(1,'Example: <strong>clear; example_syntax_1</strong>\n'); 
clear; example_syntax_1; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_syntax_2</strong>\n'); 
clear; example_syntax_2; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_syntax_3</strong>\n'); 
clear; example_syntax_3; fprintf(1,'Pausing...'); pause(3.0); 
fprintf(1,'Example: <strong>clear; example_syntax_4</strong>\n'); 
clear; example_syntax_4; 
%%
fprintf(1,'Examples completed.')
