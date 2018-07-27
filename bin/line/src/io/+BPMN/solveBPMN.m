%  SOLVEBPMN solves a BPMN model specified by the BPMN XML file FILENAME
%  and the XML extension file EXTFILENAME. The extended BPMN model is
%  transformed into an LQN model, solvedm and the results are saved in
%  XML format in the same folder as the input file, and with the same
%  name adding the suffix '-line.xml'
% 
%  Input:
%  filename:             filepath of the BPMN XML file with the model to solve
%  extFilename:          filepath of the XML extension file for the model to solve
%  options.outputFolder: path of an alternative output folder
%  options.RTdist:       1 if the response-time distribution is to be
%                        computed, 0 otherwise
%  options.RTrange:      array of double in (0,1) with the percentiles to
%                        evaluate the response-time distribution
%  options.verbose:      1 for screen output, 0 otherwise
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
