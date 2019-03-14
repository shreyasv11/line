function [simElem,simDoc] = saveXMLHeader(self, logPath)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
if isoctave
	try
    simDoc = javaObject('org.apache.xerces.dom.DocumentImpl');
    simElem = simDoc.createElement('sim');
    simDoc.appendChild(simElem);
	catch
javaaddpath(which('xercesImpl-2.11.0.jar'));
javaaddpath(which('xml-apis-2.11.0.jar'));
pkg load io;
    simDoc = javaObject('org.apache.xerces.dom.DocumentImpl');
    simElem = simDoc.createElement('sim');
    simDoc.appendChild(simElem);
end
else
    simDoc = com.mathworks.xml.XMLUtils.createDocument('sim');
    simElem = simDoc.getDocumentElement;
end
simElem.setAttribute('xmlns:xsi', self.xmlnsXsi);
simElem.setAttribute('disableStatisticStop', 'true');
simElem.setAttribute('logDecimalSeparator', '.');
simElem.setAttribute('logDelimiter', ';');
simElem.setAttribute('logPath', logPath);
simElem.setAttribute('logReplaceMode', '0');
simElem.setAttribute('maxSamples', int2str(self.maxSamples));
fname = [self.getFileName(), ['.', 'jsimg']];
simElem.setAttribute('name', fname);
simElem.setAttribute('polling', '1.0');
simElem.setAttribute('seed', int2str(self.options.seed));
simElem.setAttribute('xsi:noNamespaceSchemaLocation', 'SIMmodeldefinition.xsd');
end