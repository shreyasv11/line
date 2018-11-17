function [outputFileName] = writeJMVA(self, outputFileName)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.


if ~self.model.hasProductFormSolution
    error('JMVA requires the model to have a product-form solution. Quitting.');
end

if self.model.hasClassSwitch
    error('JMVA does not support class switching. Quitting.');
end

mvaDoc = com.mathworks.xml.XMLUtils.createDocument('model');
mvaElement = mvaDoc.getDocumentElement;
mvaElement.setAttribute('xmlns:xsi', self.xmlnsXsi);
mvaElement.setAttribute('xsi:noNamespaceSchemaLocation', 'JMTmodel.xsd');
if ~exist('outFileName','var')
    outputFileName = self.getJMVATempPath();
end

qn = self.model.getStruct();
parametersElement = mvaDoc.createElement('parameters');
classesElement = mvaDoc.createElement('classes');
classesElement.setAttribute('number',num2str(qn.nclasses));
stationsElement = mvaDoc.createElement('stations');
stationsElement.setAttribute('number',num2str(qn.nstations - sum(self.getStruct.nodetype == NodeType.Source)));
refStationsElement = mvaDoc.createElement('ReferenceStation');
refStationsElement.setAttribute('number',num2str(qn.nclasses));
algParamsElement = mvaDoc.createElement('algParams');

sourceid = self.getStruct.nodetype == NodeType.Source;
for r=1:qn.nclasses
    if isfinite(qn.njobs(r))
        classElement = mvaDoc.createElement('closedclass');
        classElement.setAttribute('population',num2str(qn.njobs(r)));
        classElement.setAttribute('name',qn.classnames{r});
    else
        classElement = mvaDoc.createElement('openclass');
        classElement.setAttribute('rate',num2str(qn.rates(sourceid,r)));
        classElement.setAttribute('name',qn.classnames{r});
    end
    classesElement.appendChild(classElement);
end

for i=1:qn.nstations
    switch self.getStruct.nodetype(self.getStruct.stationToNode(i))
        case NodeType.Delay
            statElement = mvaDoc.createElement('delaystation');
            statElement.setAttribute('name',qn.nodenames{self.getStruct.stationToNode(i)});
        case NodeType.Queue
            statElement = mvaDoc.createElement('listation');
            statElement.setAttribute('name',qn.nodenames{self.getStruct.stationToNode(i)});
            statElement.setAttribute('servers',num2str(qn.nservers(i)));
        otherwise
            continue
    end
    srvTimesElement = mvaDoc.createElement('servicetimes');
    for r=1:qn.nclasses
        statSrvTimeElement = mvaDoc.createElement('servicetime');
        statSrvTimeElement.setAttribute('customerclass',qn.classnames{r});
        val = 1/qn.rates(i,r); if ~isfinite(val) val = 0.0; end
        statSrvTimeElement.appendChild(mvaDoc.createTextNode(num2str(val)));
        srvTimesElement.appendChild(statSrvTimeElement);
    end
    statElement.appendChild(srvTimesElement);
    visitsElement = mvaDoc.createElement('visits');
    for r=1:qn.nclasses
        c = qn.chains(:,r);
        statVisitElement = mvaDoc.createElement('visit');
        statVisitElement.setAttribute('customerclass',qn.classnames{r});
        val = qn.visits{c}(i,r); if ~isfinite(val) val = 0.0; end
        statVisitElement.appendChild(mvaDoc.createTextNode(num2str(val)));
        visitsElement.appendChild(statVisitElement);
    end
    statElement.appendChild(visitsElement);
    
    stationsElement.appendChild(statElement);
end

for r=1:qn.nclasses
    c = qn.chains(:,r);
    classRefElement = mvaDoc.createElement('Class');
    classRefElement.setAttribute('name',qn.classnames{r});
    classRefElement.setAttribute('refStation',qn.nodenames{qn.stationToNode(qn.refstat(c))});
    refStationsElement.appendChild(classRefElement);
end

algTypeElement = mvaDoc.createElement('algType');
algTypeElement.setAttribute('name','MVA');
algTypeElement.setAttribute('tolerance','1.0E-7');
algTypeElement.setAttribute('maxSamples','10000');
compareAlgsElement = mvaDoc.createElement('compareAlgs');
compareAlgsElement.setAttribute('value','false');
algParamsElement.appendChild(algTypeElement);
algParamsElement.appendChild(compareAlgsElement);

parametersElement.appendChild(classesElement);
parametersElement.appendChild(stationsElement);
parametersElement.appendChild(refStationsElement);
mvaElement.appendChild(parametersElement);
mvaElement.appendChild(algParamsElement);

xmlwrite(outputFileName, mvaDoc);
end