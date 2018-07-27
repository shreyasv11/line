% function [processors, tasks, entries, physical, requesters, providers] = parseXML(filename, verbose)
%  PARSEXML_LayeredNetwork(A) parses an XML file A containing an LQN model
% 
%  Parameters:
%  filename:     path of the XML file to parse
%  verbose:      1 for screen output
% 
%  Output:
%  processors:   actual description of the LQN by means of processors, tasks, entries and activities objects
%  tasks:        list of tasks (task name, task ID, proc name, proc ID)
%  entries:      list of entries (entry name, task ID)
%  requesters:   list of activities that demand a service from an entry
%                 (act name, task ID, proc name, target entry, procID)
%  providers:    list of activities/entries that provide services
%                 (act name, entry name, task name, proc name, proc ID)
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
