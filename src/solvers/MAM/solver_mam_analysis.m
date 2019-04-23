function [QN,UN,RN,TN,CN,XN,runtime] = solver_mam_analysis(qn, options)
% [QN,UN,RN,TN,CN,XN,RUNTIME] = SOLVER_MAM_ANALYSIS(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes

Tstart = tic;

PH = qn.ph;

[QN,UN,RN,TN,CN,XN] = solver_mam(qn, PH, options);

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;

runtime = toc(Tstart);

%if options.verbose > 0
%    fprintf(1,'MAM analysis completed in %f sec\n',runtime);
%end
end
