function [simElem,simNode] = saveXMLHeader(self, logPath)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
simNode = com.mathworks.xml.XMLUtils.createDocument('sim');
simElem = simNode.getDocumentElement;
simElem.setAttribute('xmlns:xsi', self.xmlnsXsi);
simElem.setAttribute('disableStatisticStop', 'true');
simElem.setAttribute('logDecimalSeparator', '.');
simElem.setAttribute('logDelimiter', ';');
simElem.setAttribute('logPath', logPath);
simElem.setAttribute('logReplaceMode', '0');
simElem.setAttribute('maxSamples', int2str(self.maxSamples));
simElem.setAttribute('name', getFileNameWithExtension(self));
simElem.setAttribute('polling', '1.0');
simElem.setAttribute('seed', int2str(self.options.seed));
simElem.setAttribute('xsi:noNamespaceSchemaLocation', 'SIMmodeldefinition.xsd');
end
