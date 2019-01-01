classdef Queue < Station
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
    properties
        schedPolicy;
        schedStrategy;
        schedStrategyPar;
        serviceProcess;
    end
    
    methods
        %Constructor
        function self = Queue(model, name, schedStrategy)
            self = self@Station(name);
            
            classes = model.classes;
            self.input = Buffer(classes);
            self.output = Dispatcher(classes);            
			self.schedPolicy = SchedPolicy.PR;
            self.schedStrategy = SchedStrategy.PS;
            self.serviceProcess = {};
            self.server = Server(classes);
            self.numberOfServers = 1;
            self.schedStrategyPar = zeros(1,length(model.classes));
            self.setModel(model);
            self.model.addNode(self);
            
            if exist('schedStrategy','var')
                self.schedStrategy = schedStrategy;
                switch schedStrategy
                    case {SchedStrategy.PS, SchedStrategy.DPS,SchedStrategy.GPS}
                        self.schedPolicy = SchedPolicy.PR;
                        self.server = SharedServer(classes);
                    case {SchedStrategy.FCFS, SchedStrategy.LCFS, SchedStrategy.RAND, SchedStrategy.SEPT, SchedStrategy.LEPT, SchedStrategy.SJF, SchedStrategy.LJF}
                        self.schedPolicy = SchedPolicy.NP;
                        self.server = Server(classes);
                    case SchedStrategy.INF
                        self.schedPolicy = SchedPolicy.NP;
                        self.server = InfiniteServer(classes);
                        self.numberOfServers = Inf;
                    case SchedStrategy.HOL
                        self.schedPolicy = SchedPolicy.NP;
                        self.server = Server(classes);
                    otherwise
                        error(sprintf('The specified scheduling strategy (%s) is unsupported.',schedStrategy));
                end
            end
        end
        
        function setNumberOfServers(self, value)
            self.setNumServers(value);
        end
            
        function setNumServers(self, value)
            switch self.schedStrategy
                case {SchedStrategy.DPS, SchedStrategy.GPS}
                    if value ~= 1
                        error('Cannot use multi-server stations with %s scheduling.', self.schedStrategy);
                    end
                otherwise
                    self.numberOfServers = value;
            end
        end
        
        function self = setStrategyParam(self, class, weight)
            self.schedStrategyPar(class.index) = weight;
        end
        
        function setService(self, class, distribution, weight)
            if ~exist('weight','var')
                        weight=1.0;
            end
            
            self.serviceProcess{class.index} = distribution;
            self.server.serviceProcess{1, class.index}{2} = ServiceStrategy.LI;
            if distribution.isImmediate()
                self.server.serviceProcess{1, class.index}{3} = Immediate();
            else
                self.server.serviceProcess{1, class.index}{3} = distribution;
            end
            if length(self.classCap) < class.index
                self.classCap(class.index) = Inf;
            end
            self.setStrategyParam(class, weight);
        end
        
        function sections = getSections(self)
            sections = {self.input, self.server, self.output};
        end
                
    end
end