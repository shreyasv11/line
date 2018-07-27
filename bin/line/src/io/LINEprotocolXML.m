%  LINEPROTOCOLXML defines an object to control the interaction between the
%  LINE client and the server. It handles a set of instructions from the
%  LINE client and returns responses according to the results from the
%  solver
% 
%  LINEPROTOCOLXML maintains the LINE object that solves the model,
%  processes the input instructions for the solver in the LINE object, 
%  and call these solvers. 
% 
%  Properties:
%  state:        state of the protocol
%                values:  
%                EMPTY:  no model has been loaded
%                INIT:   a model has been loaded, no model has been run
%                SOLVED: a model has been run
%  myLINE:       LINE object
%  SEQ:          1 if LINE operates sequentially
%                0 (default) if LINE operates in parallel
% 
%  Copyright (c) 2012-2018, Imperial College London 
%  All rights reserved.
%
%    Reference page in Doc Center
%       doc LINEprotocolXML
%
%
