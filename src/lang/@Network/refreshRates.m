function [rates, scv] = refreshRates(self)
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.

M = self.getNumberOfStations();
K = self.getNumberOfClasses();
rates = zeros(M,K);
% determine rates
for i=1:M
    for r=1:K
        switch self.stations{i}.server.className
            case 'ServiceTunnel'
                % do nothing
                if strcmpi(class(self.stations{i}),'Source')
                    if isempty(self.stations{i}.input.sourceClasses{r}) || self.stations{i}.input.sourceClasses{r}{end}.isDisabled
                        rates(i,r) = NaN;
                        scv(i,r) = NaN;
                    elseif self.stations{i}.input.sourceClasses{r}{end}.isImmediate
                        rates(i,r) = Distrib.InfRate;
                        scv(i,r) = 0;
                    else
                        rates(i,r) = 1/self.stations{i}.input.sourceClasses{r}{end}.getMean();
                        scv(i,r) = self.stations{i}.input.sourceClasses{r}{end}.getSCV();
                 end
                end
            otherwise
                if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
                    if isempty(self.stations{i}.server.serviceProcess{r}) || self.stations{i}.server.serviceProcess{r}{end}.isDisabled 
                        rates(i,r) = NaN;
                        scv(i,r) = NaN;
                    elseif self.stations{i}.server.serviceProcess{r}{end}.isImmediate
                        rates(i,r) = Distrib.InfRate;
                        scv(i,r) = 0;
                    else
                        rates(i,r) = 1/self.stations{i}.server.serviceProcess{r}{end}.getMean();
                        scv(i,r) = self.stations{i}.server.serviceProcess{r}{end}.getSCV();
                    end
                end
        end
    end
end
if ~isempty(self.qn)
    self.qn.setService(rates, scv);
end
end