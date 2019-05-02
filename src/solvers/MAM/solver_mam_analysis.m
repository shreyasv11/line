function [QN,UN,RN,TN,CN,XN,runtime] = solver_mam_analysis(qn, options)
% [QN,UN,RN,TN,CN,XN,RUNTIME] = SOLVER_MAM_ANALYSIS(QN, OPTIONS)

% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

M = qn.nstations;    %number of stations
K = qn.nclasses;    %number of classes

Tstart = tic;

switch options.method
    case 'srvscaling'
        % service distributuion per class scaled by utilization used as 
        % departure process
        PH = qn.ph;
        [QN,UN,RN,TN,CN,XN] = solver_mam(qn, PH, options);
    case {'default', 'arvscaling'}
        % arrival process per chain rescaled by visits at each node
        PH = qn.ph;
        [QN,UN,RN,TN,CN,XN] = solver_mam_basic(qn, PH, options);
    case 'poisson'
        % analyze the network with Poisson streams
        POI = cell(M,K);
        for i=1:M
            for k=1:K
                POI{i,k} = map_exponential(1/qn.rates(i,k));
            end
        end
        [QN,UN,RN,TN,CN,XN] = solver_mam_basic(qn, POI, options);
    otherwise
        error('Unknown method.');
end

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
