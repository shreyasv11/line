function [result, parsed] = getResults(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

try
    fileName = strcat(self.getFilePath(),'jsimg',filesep,self.getFileName(),'.jsimg-result.jsim');
    if exist(fileName,'file')
		Pref.Str2Num = 'always';
        parsed = xml_read(fileName,Pref);
    else
        error('JMT did not product a result file, the simulation must have failed.');
    end
catch me
    error('Unknown error upon parsing JMT result file. ');
end
self.result.('solver') = self.getName();
self.result.('model') = parsed.ATTRIBUTE;
self.result.('metric') = {parsed.measure.ATTRIBUTE};
result = self.result;
end
