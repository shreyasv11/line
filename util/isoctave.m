function r = isoctave ()
% r = isoctave()
% Returns true if run in GNU OCTAVE
%
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
  persistent x;
  if (isempty (x))
    x = exist ('OCTAVE_VERSION', 'builtin');
  end
  r = x;
end
