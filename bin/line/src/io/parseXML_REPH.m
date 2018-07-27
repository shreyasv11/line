%  PARSEXML_REPH parses an XML file describing a 
%  set of Random Environments (REs) with PH holding times
%  If any of the RE has PH holding times, it returns a list of REPH objects,
%  and the indicator REPH = 1. Otherwise, it returns a simpler list of RE
%  objects and REPH = 0. 
% 
%  Parameters: 
%  doc:          head of the XML object to parse
%  verbose:      1 for screen output 
% 
%  Output:
%  REs: random environments description
%  REPHflag: equal to 1 if objects returned are REPH, 0 if these are RE.
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
