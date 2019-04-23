classdef Logger < Node
    % A node where jobs are logged upon passage.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        fileName;
        filePath;
        schedPolicy;
        schedStrategy;
        cap;
    end
    
    properties (Access=private)
        wantStartTime;
        wantLoggerName;
        wantTimestamp;
        wantJobID;
        wantJobClass;
        wantTimeSameClass;
        wantTimeAnyClass;
    end
    
    methods
        %Constructor
        function self = Logger(model, name, logFileName)
            % SELF = LOGGER(MODEL, NAME, LOGFILENAME)
            
            self@Node(name);
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
            self.schedPolicy = SchedStrategyType.NP;
            self.schedStrategy = SchedStrategy.FCFS;
            self.server = LogTunnel();
            self.setStartTime(false);
            self.setLoggerName(false);
            self.setTimestamp(true);
            self.setJobID(true);
            self.setJobClass(true);
            self.setTimeSameClass(false);
            self.setTimeAnyClass(false);
            self.setModel(model);
            self.model.addNode(self);
        end
        
        function ret = getStartTime(self)
            % RET = GETSTARTTIME(SELF)
            
            ret = self.wantStartTime;
        end
        function ret = getLoggerName(self)
            % RET = GETLOGGERNAME(SELF)
            
            ret = self.wantLoggerName;
        end
        function ret = getTimestamp(self)
            % RET = GETTIMESTAMP(SELF)
            
            ret = self.wantTimestamp;
        end
        function ret = getJobID(self)
            % RET = GETJOBID(SELF)
            
            ret = self.wantJobID;
        end
        function ret = getJobClass(self)
            % RET = GETJOBCLASS(SELF)
            
            ret = self.wantJobClass;
        end
        function ret = getTimeSameClass(self)
            % RET = GETTIMESAMECLASS(SELF)
            
            ret = self.wantTimeSameClass;
        end
        function ret = getTimeAnyClass(self)
            % RET = GETTIMEANYCLASS(SELF)
            
            ret = self.wantTimeAnyClass;
        end
        
        function setStartTime(self, bool)
            % SETSTARTTIME(SELF, BOOL)
            
            if bool
                self.wantStartTime = 'true';
            else
                self.wantStartTime = 'false';
            end
        end
        
        function setTimestamp(self, bool)
            % SETTIMESTAMP(SELF, BOOL)
            
            if bool
                self.wantTimestamp = 'true';
            else
                self.wantTimestamp = 'false';
            end
        end
        
        function setLoggerName(self, bool)
            % SETLOGGERNAME(SELF, BOOL)
            
            if bool
                self.wantLoggerName = 'true';
            else
                self.wantLoggerName = 'false';
            end
        end
        
        function setTimeSameClass(self, bool)
            % SETTIMESAMECLASS(SELF, BOOL)
            
            if bool
                self.wantTimeSameClass = 'true';
            else
                self.wantTimeSameClass = 'false';
            end
        end
        
        function setTimeAnyClass(self, bool)
            % SETTIMEANYCLASS(SELF, BOOL)
            
            if bool
                self.wantTimeAnyClass = 'true';
            else
                self.wantTimeAnyClass = 'false';
            end
        end
        
        function setJobID(self, bool)
            % SETJOBID(SELF, BOOL)
            
            if bool
                self.wantJobID = 'true';
            else
                self.wantJobID = 'false';
            end
        end
        
        function setJobClass(self, bool)
            % SETJOBCLASS(SELF, BOOL)
            
            if bool
                self.wantJobClass = 'true';
            else
                self.wantJobClass = 'false';
            end
        end
        
        function setProbRouting(self, class, destination, probability)
            % SETPROBROUTING(SELF, CLASS, DESTINATION, PROBABILITY)
            
            setRouting(self, class, RoutingStrategy.PROB, destination, probability);
        end
        
        function setScheduling(self, class, strategy)
            % SETSCHEDULING(SELF, CLASS, STRATEGY)
            
            self.input.inputJobClasses{1, class.index}{2} = strategy;
        end
        
        function sections = getSections(self)
            % SECTIONS = GETSECTIONS(SELF)
            
            sections = {self.input, self.server, self.output};
        end
    end
end
