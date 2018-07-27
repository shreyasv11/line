%  PURPOSE:
%  search for a RCAT product-form by relaxation-linearization + cuts
% ---------------------------------------------------
%  USAGE: [x, pi, Q, stats] = autocat(R, AP, SOLVER, POLICY)
%  where:
% ---------------------------------------------------
%  RETURNS a vector of output arguments composed of:
%  --------------------------------------------------
%  REFERENCES:
%  --------------------------------------------------
%  VERSIONING:
% 
%  0.0.7 - 31/Oct/2010 - added approximations
%  0.0.6 - 29/Oct/2010 - added zero potential relaxation
%  0.0.5 - 24/Oct/2010 - added soft constraints, policies, minresidual
%  0.0.4 - 20/Oct/2010 - added tlpr and decomposed into multiple functions
%  0.0.3 - 15/Oct/2010 - various fixes and new two-way synchs format
%  0.0.2 - 26/Sep/2010 - now only bound update iterations
%  0.0.1 - 14/Sep/2010 - basic RCAT implementation
% ---------------------------------------------------
%  EXAMPLE:
%  Date: 14-Sep-2010 18:40:25
%
