function [outputFolder, RT, RTrange, max_iter, solver, verbose] = parseOptions(options)
% PARSEOPTIONS parses a structure with the options for the solvers of
% different models. Sets default values if not
%
% Input:
% options:              structure that defines the following options:
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to
%                       evaluate the response-time distribution
% options.solver:       type of solver to use: FLUID or AMVA
% options.max_iter:      maximum number of iterations for the FLUID solver
% options.verbose:      1 for screen output, 0 otherwise
%
% Output:
% outputFolder:         path of an alternative output folder
% RT:                   1 if the response-time distribution is to be
%                       computed, 0 otherwise
% RTrange:              array of double in (0,1) with the percentiles to
%                       evaluate the response-time distribution
% solver:               type of solver to use: FLUID or AMVA
% max_iter:              maximum number of iterations for the FLUID solver
% verbose:              1 for screen output, 0 otherwise
%
% Copyright (c) 2015-2018, Imperial College London
% All rights reserved.

%% read options - set defaults if no options are provided
if nargin == 0 || (nargin == 1 && isempty(options))
    options = [];
end
if isfield(options, 'outputFolder') && ~isempty(options.outputFolder)
    if exist(options.outputFolder, 'dir')
        outputFolder = options.outputFolder;
    else
        warning(['Output folder ', options.outputFolder,' not found']);
        disp('Using default folder.');
        outputFolder = [];
    end
else
    outputFolder = [];
end
% RT
if isfield(options, 'RTdist') && ~isempty(options.RTdist)
    RT = options.RTdist;
else
    RT = 0;
end
if isfield(options, 'RTrange') && ~isempty(options.RTrange)
    RTrange = options.RTrange;
    if size(RTrange,2) > 1 && size(RTrange,1) == 1
        RTrange = RTrange';
    elseif size(RTrange,2) > 1 && size(RTrange,1) > 1
        warning('RTrange is not a vector. Ignoring input');
        RTrange = [];
        RT = 0;
    end
else
    RTrange = [];
end
% verbose
if isfield(options, 'verbose') && ~isempty(options.verbose)
    verbose = options.verbose;
else
    verbose = 0;
end
solver = 0; % AUTO

if isfield(options, 'verbose')
    if options.verbose
        fprintf(1,'Solver not specified. Using default: FLUID solver.\n');
    end
end

% max iter
if isfield(options, 'max_iter') && ~isempty(options.max_iter)
    max_iter = options.max_iter;
else
    max_iter = 1000;
end
end