%  DEMANDSERVICEREQUEST defines DEMANDSERVICEREQUEST objects, as part of a Performance Model Interchange Format (PMIF) model. 
% 
%  Properties:
%  workloadName:         name of the workload associated to this service request (string)
%  serverID:             name of the server where this ervice request takes place (string)
%  serviceDemand:        mean demand posed by the service request on the server (double)
%  numberVisits:         number of visits of this request class to this server (integer)
%  timeUnits:            time units in which the service time is measured (string - optional)
%  transits:             list of (dest,prob) tuples describing the routing
%                        after the visit to the servic node. Each entry holds
%                        the name of the destination node (dest) and the
%                        probability (prob)
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc PMIF.demandServiceRequest
%
%
