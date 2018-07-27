%  PARSEXML_BPMNEXTENSIONS(A) parses an XML file A describing extensions to BPMN 
%  according to the BPMNextensions schema
% 
%  Parameters: 
%    doc:          head of the XML object to parse
%    verbose:      1 for screen output 
% 
%  Output:
%    modelExt:       BPMN extension containing 2 elements:
%    resources:      list of resources to use in the BPMN model
%    taskRes:        list of tasks (column 1), their associated resource (column 2), 
%                    and the index of the assignment in the associated resource (column 3)                
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
