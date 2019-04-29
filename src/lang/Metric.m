classdef Metric < Copyable
    % An output metric of a Solver, such as a performance index.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        ResidT = 'Residence Time'; % Response Time * Visits
        RespT = 'Response Time'; % Response Time for one Visit
        DropRate = 'Drop Rate';
        QLen = 'Number of Customers';
        QueueT = 'Queue Time';
        FCRWeight = 'FCR Total Weight';
        FCRMemOcc = 'FCR Memory Occupation';
        FJQLen = 'Fork Join Response Time';
        FJRespT = 'Fork Join Response Time';
        RespTSink = 'Response Time per Sink';
        SysDropR = 'System Drop Rate';
        SysQLen = 'System Number of Customers';
        SysPower = 'System Power';
        SysRespT = 'System Response Time';
        SysTput = 'System Throughput';
        Tput = 'Throughput';
        ArvR = 'Arrival Rate';
        TputSink = 'Throughput per Sink';
        Util = 'Utilization';
        TranQLen = 'Tran Number of Customers';
        TranUtil = 'Tran Utilization';
        TranTput = 'Tran Throughput';
        TranRespT = 'Tran Response Time';
    end
    
    
    properties
        type;
        class;
        station;
        simConfInt;
        simMaxRelErr;
        disabled;
        transient;
    end
    
    methods (Hidden)
        %Constructor
        function self = Metric(type, class, station)
            % SELF = METRIC(TYPE, CLASS, STATION)
            
            self.type = type;
            self.class = class;
            if exist('station','var')
                self.station = station;
            else
                self.station = '';
                self.station.name = '';
            end
            switch self.type
                case {Metric.TranQLen, Metric.TranUtil, Metric.TranTput}
                    self.simConfInt = NaN;
                    self.simMaxRelErr = NaN;
                otherwise % currently used only by JMT
                    self.simConfInt = 0.99;
                    self.simMaxRelErr = 0.03;
            end
            self.disabled = 0;
            self.transient = false;
            switch type
                case {Metric.TranQLen, Metric.TranTput, Metric.TranUtil}
                    self.transient = true;
            end
        end
    end
    
    methods
        function self = setTran(self, bool)
            % SELF = SETTRAN(BOOL)
            
            self.transient = bool;
        end
        
        function bool = isTran(self)
            % BOOL = ISTRAN()
            
            bool = self.transient;
        end
        
        function bool = isDisabled(self)
            % BOOL = ISDISABLED()
            
            bool = self.disabled;
        end
        
        function self = disable(self)
            % SELF = DISABLE()
            
            self.disabled = 1;
        end
        
        function self = enable(self)
            % SELF = ENABLE()
            
            self.disabled = 0;
        end
        
        function value = get(self, results, model)
            % VALUE = GET(RESULTS, MODEL)
            
            if self.disabled == 1
                value = NaN;
                return
            end
            
            switch results.solver
                case 'SolverJMT'
                    
                    if ~exist('model','var')
                        error('Wrong syntax, use Metric.get(results,model).\n');
                    end
                    classnames = model.getClassNames();
                    stationnames = model.getStationNames();
                    i = findstring(stationnames,self.station.name);
                    r = findstring(classnames,self.class.name);
                    switch self.type
                        case Metric.TranTput
                            %results.Tran.Avg.T{i,r}.Name = sprintf('Throughput (station %d, class %d)',i,r);
                            %results.Tran.Avg.T{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.T{i,r};
                            return
                        case Metric.TranUtil
                            %results.Tran.Avg.U{i,r}.Name = sprintf('Utilization (station %d, class %d)',i,r);
                            %results.Tran.Avg.U{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.U{i,r};
                            return
                        case Metric.TranQLen
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.Q{i,r};
                            return
                        case Metric.TranRespT
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.R{i,r};
                            return
                    end
                    
                    for i=1:length(results.metric)
                        type = self.type;
                        switch self.type
                            case Metric.TranQLen
                                type = Metric.QLen;
                            case Metric.TranUtil
                                type = Metric.Util;
                            case Metric.TranTput
                                type = Metric.Tput;
                            case Metric.TranRespT
                                type = Metric.RespT;
                        end
                        if strcmp(results.metric{i}.class, self.class.name) && strcmp(results.metric{i}.measureType,type) && strcmp(results.metric{i}.station, self.station.name)
                            chain = model.getChains{model.getClassChain(self.class.name)};
                            switch self.class.type
                                case 'closed'
                                    N = model.getNumberOfJobs();
                                    if results.metric{i}.analyzedSamples > sum(N(cell2mat(chain.index))) % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                                        value = results.metric{i}.meanValue;
                                    else
                                        value = 0; % transient metric, long term avg is 0
                                    end
                                case 'open'
                                    if results.metric{i}.analyzedSamples >= 0 % we assume that open classes are always recurrent
                                        value = results.metric{i}.meanValue;
                                    else
                                        value = 0; % transient metric, long term avg is 0
                                    end
                            end
                            break;
                        end
                    end
                otherwise % another LINE solver
                    if ~exist('model','var')
                        error('Wrong syntax, use Metric.get(results,model).\n');
                    end
                    classnames = model.getClassNames();
                    stationnames = model.getStationNames();
                    i = findstring(stationnames,self.station.name);
                    r = findstring(classnames,self.class.name);
                    switch self.type
                        case Metric.Util
                            value = results.Avg.U(i,r);
                        case Metric.SysRespT
                            value = results.Avg.C(i,r);
                        case Metric.SysTput
                            value = results.Avg.X(i,r);
                        case Metric.RespT
                            value = results.Avg.R(i,r);
                        case Metric.Tput
                            value = results.Avg.T(i,r);
                        case Metric.QLen
                            value = results.Avg.Q(i,r);
                        case Metric.TranTput
                            %results.Tran.Avg.T{i,r}.Name = sprintf('Throughput (station %d, class %d)',i,r);
                            %results.Tran.Avg.T{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.T{i,r};
                        case Metric.TranUtil
                            %results.Tran.Avg.U{i,r}.Name = sprintf('Utilization (station %d, class %d)',i,r);
                            %results.Tran.Avg.U{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.U{i,r};
                        case Metric.TranQLen
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.Q{i,r};
                        case Metric.TranRespT
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.R{i,r};
                    end
            end
        end
    end
end

