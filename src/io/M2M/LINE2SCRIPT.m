function model = LINE2SCRIPT(model, filename)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
qn = model.getStruct;
if exist('filename','var')
    fid = fopen(filename,'w'); % discard
    QN2SCRIPT(qn, model.getName(), fid);
    fclose(fid);
else
    QN2SCRIPT(qn, model.getName(), 1);
end
end