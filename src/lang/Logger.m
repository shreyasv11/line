classdef Logger < Node
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        fileName;
        filePath;
        schedPolicy;
        schedStrategy;
        cap;
        wantExecTimestamp;
        wantLoggerName;
        wantTimeStamp;
        wantJobID;
        wantJobClass;
        wantTimeSameClass;
        wantTimeAnyClass;
    end
    
    methods
        %Constructor
        function self = Logger(model, name, logFileName)
            self = self@Node(name);
            [~,fileName,fileExt] = fileparts(logFileName);
            self.fileName = sprintf('%s%s',fileName,fileExt);
            if isempty(model.getLogPath)
                error('To instantiate a Logger, first use setLogPath method on the Network object to define the global path to save logs.');
            else
                self.filePath = model.getLogPath;
            end
            classes = model.classes;
            self.input = Buffer(classes);
            self.output = Dispatcher(classes);
            self.cap = Inf;
            self.schedPolicy = SchedPolicy.NP;
            self.schedStrategy = SchedStrategy.FCFS;
            self.server = LogTunnel();
            self.wantExecTimestamp = 'false';
            self.wantLoggerName = 'false';
            self.wantTimeStamp = 'true';
            self.wantJobID = 'true';
            self.wantJobClass = 'true';
            self.wantTimeSameClass = 'false';
            self.wantTimeAnyClass = 'false';
            self.setModel(model);
            self.model.addNode(self);
        end
        
        function setProbRouting(self, class, destination, probability)
            setRouting(self, class, 'Probabilities', destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            self.input.inputJobClasses{1, class.index}{2} = strategy;
        end
        
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
    end
end