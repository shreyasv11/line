function [result, parsed] = getResultsJMVA(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

try
    fileName = strcat(self.getFilePath(),'jmva',filesep,self.getFileName(),'.jmva-result.jmva');
    if exist(fileName,'file')
        Pref.Str2Num = 'always';
        parsed = xml_read(fileName,Pref);
    else
        error('JMT did not output a result file, the analysis has likely failed.');
    end
catch me
    error('Unknown error upon parsing JMT result file. ');
end
self.result.('solver') = self.getName();
self.result.('model') = parsed.ATTRIBUTE;
self.result.('metric') = {};

qn = self.model.getStruct;
statres = parsed.solutions.algorithm.stationresults;

for i=1:qn.nstations
    switch qn.nodetype(self.getStruct.stationToNode(i))
        case NodeType.Source
            for r=1:qn.nclasses
                s = struct();
                s.('alfa') = NaN;
                s.('analyzedSamples') = Inf;
                s.('class') = qn.classnames{r};
                s.('discardedSamples') = 0;
                s.('lowerLimit') = qn.rates(i,r);
                s.('maxSamples') = Inf;
                s.('meanValue') = qn.rates(i,r);
                s.('measureType') = Perf.Tput;
                s.('nodeType') = 'station';
                s.('precision') = Inf;
                s.('station') = qn.nodenames{self.getStruct.stationToNode(i)};
                s.('successful') = 'true';
                s.('upperLimit') = qn.rates(i,r);
                self.result.metric{end+1} = s;
                
                s = struct();
                s.('alfa') = NaN;
                s.('analyzedSamples') = Inf;
                s.('class') = qn.classnames{r};
                s.('discardedSamples') = 0;
                s.('lowerLimit') = 0;
                s.('maxSamples') = Inf;
                s.('meanValue') = 0;
                s.('measureType') = Perf.QLen;
                s.('nodeType') = 'station';
                s.('precision') = Inf;
                s.('station') = qn.nodenames{self.getStruct.stationToNode(i)};
                s.('successful') = 'true';
                s.('upperLimit') = 0;
                self.result.metric{end+1} = s;
                
                s = struct();
                s.('alfa') = NaN;
                s.('analyzedSamples') = Inf;
                s.('class') = qn.classnames{r};
                s.('discardedSamples') = 0;
                s.('lowerLimit') = 0;
                s.('maxSamples') = Inf;
                s.('meanValue') = 0;
                s.('measureType') = Perf.RespT;
                s.('nodeType') = 'station';
                s.('precision') = Inf;
                s.('station') = qn.nodenames{self.getStruct.stationToNode(i)};
                s.('successful') = 'true';
                s.('upperLimit') = 0;
                self.result.metric{end+1} = s;
                
                s = struct();
                s.('alfa') = NaN;
                s.('analyzedSamples') = Inf;
                s.('class') = qn.classnames{r};
                s.('discardedSamples') = 0;
                s.('lowerLimit') = 0;
                s.('maxSamples') = Inf;
                s.('meanValue') = 0;
                s.('measureType') = Perf.Util;
                s.('nodeType') = 'station';
                s.('precision') = Inf;
                s.('station') = qn.nodenames{self.getStruct.stationToNode(i)};
                s.('successful') = 'true';
                s.('upperLimit') = 0;
                self.result.metric{end+1} = s;
            end
    end
end

for i=1:length(statres)
    classres = statres(i).classresults;
    for r=1:length(classres)
        for m=1:length(classres(r).measure)
            s = struct();
            s.('alfa') = NaN;
            s.('analyzedSamples') = Inf;
            s.('class') = classres(r).ATTRIBUTE.customerclass;
            s.('discardedSamples') = 0;
            s.('lowerLimit') = classres(r).measure(m).ATTRIBUTE.meanValue;
            s.('meanValue') = classres(r).measure(m).ATTRIBUTE.meanValue;
            s.('upperLimit') = classres(r).measure(m).ATTRIBUTE.meanValue;
            s.('maxSamples') = Inf;
            switch classres(r).measure(m).ATTRIBUTE.measureType
                case 'Residence time'
                    s.('measureType') = 'Response Time';
                    c = qn.chains(:,r);
                    s.meanValue = s.meanValue / qn.visits{c}(i,r);
                case 'Utilization'
                    s.lowerLimit = s.lowerLimit / qn.nservers(i);
                    s.meanValue = s.meanValue / qn.nservers(i);
                    s.upperLimit = s.upperLimit / qn.nservers(i);
                    s.('measureType') = classres(r).measure(m).ATTRIBUTE.measureType;
                otherwise
                    s.('measureType') = classres(r).measure(m).ATTRIBUTE.measureType;
            end
            s.('nodeType') = 'station';
            s.('precision') = Inf;
            s.('station') = statres(i).ATTRIBUTE.station;
            s.('successful') = classres(r).measure(m).ATTRIBUTE.successful;
            self.result.metric{end+1} = s;
        end
    end
end
result = self.result;
end