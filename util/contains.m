function retval = contains(varargin)
if isoctave
    retval = strfind(varargin{1},varargin{2});
else
    if length(varargin) == 2
        retval = builtin('contains',varargin{1},varargin{2});
    else
        retval = builtin('contains',varargin{1},varargin{2},varargin{3},varargin{4});
    end
end
end
