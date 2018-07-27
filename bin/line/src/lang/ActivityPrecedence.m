%  ActivityPrecedence defines objects used to determine
%  the order in which the activities, in a Layered Queueing Network (LQN) model, are executed.
%  More details on activities and their role in LQN models can be found
%  on the LINE documentation, available at http://line-solver.sf.net
% 
%  Properties:
%  pres:                 list of predecessor activies that must be completed to activite this ActivityPrecedence rule (string array)
%  posts:                list of sucessor activities that can start execution when this ActivityPrecedence rule is active (string array)
%  preType:              type of the condition among the predecessor activities, either 'single' or 'OR' (string)
%  postType:             type of the condition among the sucessor activities, either 'single' or 'OR' (string)
%  postProbs:            in the case of postType=OR, this array lists the probabilities
%                        of executing each of the successor activities in postsProbs (double array)
% 
%  Copyright (c) 2012-2018, Imperial College London
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc ActivityPrecedence
%
%
