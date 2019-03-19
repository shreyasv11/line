classdef TimeSeries < PointProcess
    % Copyright (c) 2012-Present, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        function self = TimeSeries(className, numPar)
            self = self@PointProcess(className,numPar);
        end
    end
    
    methods
        function transform(self, filterType, filterParam)
            if isempty(self.data)
                self.load();
            end
            I = length(self.data);
            switch filterType
                case ProcessFilter.Shuffle
                    self.data=self.data(randperm(I));
                case ProcessFilter.MovingAvg
                    wndsz = filterParam;
                    inData = [self.data; zeros(wndsz-1,1)];
                    for i=1:I
                        self.data(i) = mean(inData(i:(i+wndsz-1)));
                    end
            end
        end
        
        function summary(self)
            if isempty(self.data)
                self.load();
            end
            MEAN = self.getMean;
            MED = median(self.data);
            SCV = self.getSCV;
            SKEW = skewness(self.data);
            QUART = [prctile(self.data,25),prctile(self.data,50),prctile(self.data,75)];
            TAILS1PERC = [prctile(self.data,95),prctile(self.data,(1-1e-6)*100)];
            MINMAX = [min(self.data),max(self.data)];
            MAD = mad(self.data,1); %median based mad
            fprintf(1,'Replayer: length=%d NaNs=%d\nMoments: mean=%f scv=%f cv=%f skew=%f\nPercentiles: p25=%f p50=%f p75=%f p95=%f\nOrder: min=%f max=%f median=%f mad=%f\n',length(self.data),sum(isnan(self.data)),MEAN,SCV,sqrt(SCV),SKEW,QUART(1),QUART(2),QUART(3),TAILS1PERC(1),MINMAX(1),MINMAX(2),MED,MAD);
        end
    end
end