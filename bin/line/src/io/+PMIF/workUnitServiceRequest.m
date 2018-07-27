%  WORKUNITSERVICEREQUEST defines WORKUNITSERVICEREQUEST objects, as part of a Performance Model Interchange Format (PMIF) model. 
% 
%  Properties:
%  workloadName:         name of the workload associated to this service request (string)
%  serverID:             name of the server where this ervice request takes place (string)
%  numberVisits:         number of visits of this request class to this server (integer)
%  transits:             list of (dest,prob) tuples describing the routing
%                        after the visit to the servic node. Each entry holds
%                        the name of the destination node (dest) and the
%                        probability (prob)
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc PMIF.workUnitServiceRequest
%
%
