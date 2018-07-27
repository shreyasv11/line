%  LINE_OBJ defines the LINE object that processes the models, calling
%  the necessary scripts to parse the XML description, solve the performance
%  model, and export the resuls to an XML file
% 
%  Properties:
%  myCluster:    cluster to solve models in parallel
%  myJobs:       list of jobs submitted to the cluster
%  jobTasks:     list of file names of the tasks in each job
%  jobTaskREs:   filenames (RE-XML) of tasks (models) in each job
%  iter_max:      maximum number of iterations of the blending algorithm
%  RT            1 if response time distribution is to be computed; 0 otherwise
%  RTrange:      range for the computation of RT distribution
%  PARALLEL:     0 for sequential execution, 1 for job-based parallel execution, 2 for parfor execution
%  verbose:      1 for screen output, 0 otherwise
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc LINE_obj
%
%
