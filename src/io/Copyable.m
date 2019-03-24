% Copyable allows to perform deep-copy of objects via the copy() method. 
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
classdef Copyable < handle
%classdef Copyable < matlab.mixin.Copyable
%The class is needed to ensure reproducible behavior in both MATLAB and Octave.
    
    methods
        function newObj = copy(obj)
            if isoctave % or matlab versions less than 7.11
                % Other - serialize via temp file (slower)
                fname = [tempname '.mat'];
                save(fname, 'obj');
                newObj = load(fname);
                newObj = newObj.obj;
                delete(fname);
            else
                % MATLAB R2010b or newer - directly in memory (faster)
                objByteArray = getByteStreamFromArray(obj);
                newObj = getArrayFromByteStream(objByteArray);
            end
        end        
    end
end
