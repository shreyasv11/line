function [outputFileName] = writeJMVA(self, outputFileName)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

if ~self.model.hasProductFormSolution
    error('JMVA requires the model to have a product-form solution. Quitting.');
end

if self.model.hasClassSwitch
    %    error('JMVA does not support class switching. Quitting.');
end

mvaDoc = com.mathworks.xml.XMLUtils.createDocument('model');
mvaElement = mvaDoc.getDocumentElement;
mvaElement.setAttribute('xmlns:xsi', self.xmlnsXsi);
mvaElement.setAttribute('xsi:noNamespaceSchemaLocation', 'JMTmodel.xsd');
if ~exist('outFileName','var')
    outputFileName = self.getJMVATempPath();
end

qn = self.model.getStruct();
%%%%%%%%%%
M = qn.nstations;    %number of stations
NK = qn.njobs';  % initial population per class
C = qn.nchains;
SCV = qn.scv;

% determine service times
ST = 1./qn.rates;
ST(isnan(qn.rates))=0;
SCV(isnan(SCV))=1;

alpha = zeros(qn.nstations,qn.nclasses);
Vchain = zeros(qn.nstations,qn.nchains);
for c=1:qn.nchains
    inchain = find(qn.chains(c,:));
    for i=1:qn.nstations
        Vchain(i,c) = sum(qn.visits{c}(i,inchain)) / sum(qn.visits{c}(qn.refstat(inchain(1)),inchain));
        for k=inchain
            alpha(i,k) = alpha(i,k) + qn.visits{c}(i,k) / sum(qn.visits{c}(i,inchain));
        end
    end
end
Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;
alpha(alpha<1e-12)=0;

Lchain = zeros(M,C);
STchain = zeros(M,C);

SCVchain = zeros(M,C);
Nchain = zeros(1,C);
refstatchain = zeros(C,1);
for c=1:qn.nchains
    inchain = find(qn.chains(c,:));
    isOpenChain = any(isinf(qn.njobs(inchain)));
    for i=1:qn.nstations
        % we assume that the visits in L(i,inchain) are equal to 1
        Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
        STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
        if isOpenChain && i == qn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
            STchain(i,c) = 1 / sumfinite(qn.rates(i,inchain)); % ignore degenerate classes with zero arrival rates
        else
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';            
        end
        SCVchain(i,c) = SCV(i,inchain) * alpha(i,inchain)';
    end
    Nchain(c) = sum(NK(inchain));
    refstatchain(c) = qn.refstat(inchain(1));
    if any((qn.refstat(inchain(1))-refstatchain(c))~=0)
        error(sprintf('Classes in chain %d have different reference station.',c));
    end
end
STchain(~isfinite(STchain))=0;
Lchain(~isfinite(Lchain))=0;
%%%%%%%%%%
parametersElement = mvaDoc.createElement('parameters');
classesElement = mvaDoc.createElement('classes');
classesElement.setAttribute('number',num2str(qn.nchains));
stationsElement = mvaDoc.createElement('stations');
stationsElement.setAttribute('number',num2str(qn.nstations - sum(self.getStruct.nodetype == NodeType.Source)));
refStationsElement = mvaDoc.createElement('ReferenceStation');
refStationsElement.setAttribute('number',num2str(qn.nchains));
algParamsElement = mvaDoc.createElement('algParams');

sourceid = self.getStruct.nodetype == NodeType.Source;
for c=1:qn.nchains
    if isfinite(sum(qn.njobs(qn.chains(c,:))))
        classElement = mvaDoc.createElement('closedclass');
        classElement.setAttribute('population',num2str(Nchain(c)));
        classElement.setAttribute('name',sprintf('Chain%02d',c));
    else
        classElement = mvaDoc.createElement('openclass');
        classElement.setAttribute('population',num2str(sum(qn.rates(sourceid,qn.chains(c,:)))));
        classElement.setAttribute('name',sprintf('Chain%02d',c));
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
    for c=1:qn.nchains
        statSrvTimeElement = mvaDoc.createElement('servicetime');
        statSrvTimeElement.setAttribute('customerclass',sprintf('Chain%02d',c));        
        statSrvTimeElement.appendChild(mvaDoc.createTextNode(num2str(STchain(i,c))));
        srvTimesElement.appendChild(statSrvTimeElement);
    end
    statElement.appendChild(srvTimesElement);
    visitsElement = mvaDoc.createElement('visits');
    for c=1:qn.nchains
        statVisitElement = mvaDoc.createElement('visit');
        statVisitElement.setAttribute('customerclass',sprintf('Chain%02d',c));
        statVisitElement.appendChild(mvaDoc.createTextNode(num2str(Lchain(i,c) ./ STchain(i,c))));
        visitsElement.appendChild(statVisitElement);
    end
    statElement.appendChild(visitsElement);
    
    stationsElement.appendChild(statElement);
end

for c=1:qn.nchains
    classRefElement = mvaDoc.createElement('Class');
    classRefElement.setAttribute('name',sprintf('Chain%d',c));
    classRefElement.setAttribute('refStation',qn.nodenames{qn.stationToNode(refstatchain(c))});
    refStationsElement.appendChild(classRefElement);
end

algTypeElement = mvaDoc.createElement('algType');
switch self.options.method
    case {'jmva.recal'}
        algTypeElement.setAttribute('name','RECAL');
    case {'jmva.comom'}
        algTypeElement.setAttribute('name','CoMoM');
    case {'jmva.chow'}
        algTypeElement.setAttribute('name','Chow');
    case {'jmva.bs','jmva.amva'}
        algTypeElement.setAttribute('name','Bard-Schweitzer');
    case {'jmva.aql'}
        algTypeElement.setAttribute('name','AQL');
    case {'jmva.lin'}
        algTypeElement.setAttribute('name','Linearizer');
    case {'jmva.dmlin'}
        algTypeElement.setAttribute('name','De Souza-Muntz Linearizer');
    otherwise
        algTypeElement.setAttribute('name','MVA');
end
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