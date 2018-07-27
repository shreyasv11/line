%  SOLVEPMIF solves a (set of) PMIF model(s) specified by the path
%  PMIFfilepath, which can be a single file or a folder with several files.
%  For each file analyzed, the results are saved in XML format in the same
%  folder as the input file, and with the same name adding the suffix
%  '-line.xml'
% 
%  Input:
%  PMIFfilepath:         filepath of the PMIF XML file with the model to solve
%  options:              structure that defines the following options:
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
