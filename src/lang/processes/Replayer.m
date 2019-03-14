classdef Replayer < TimeSeries
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        data;
    end
    
    methods
        %Constructor
        function self = Replayer(fileName)
            self = self@TimeSeries('Replayer',1);
            setParam(self, 1, 'fileName', fileName, 'java.lang.String');
            if ischar(fileName)
                self.data = [];
                % JMT requires full file
                javaFileObj = java.io.File(fileName);
                if ~javaFileObj.isAbsolute()
                    fileName = fullfile(pwd,fileName);
                end
                self.javaClass = 'jmt.engine.random.Replayer';
                self.javaParClass = 'jmt.engine.random.ReplayerPar';
            end
        end
        
        function load(self)
            fileName = self.getParam(1).paramValue;
            self.data = load(fileName);
            self.data = self.data(:);
        end
        
        function unload(self)
            self.data = [];
        end
        
        function ex = getMean(self)
            if isempty(self.data)
                self.load();
            end
            ex = mean(self.data);
        end
        
        function SCV = getSCV(self)
            if isempty(self.data)
                self.load();
            end
            SCV = var(self.data)/mean(self.data)^2;
        end

        function distr = fitCox(self)
            distr = Cox2.fit(self.getMean,self.getSCV);
        end
    end
end

