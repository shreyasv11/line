classdef PerfIndex < matlab.mixin.Copyable
% Copyright (c) 2012-2018, Imperial College London
% All rights reserved.
    
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
        function self = PerfIndex(type, class, station)
            self.type = type;
            self.class = class;
            if exist('station','var')
                self.station = station;
            else
                self.station = '';
                self.station.name = '';
            end
            switch self.type
              	case {Perf.TranQLen, Perf.TranUtil, Perf.TranTput}
                    self.simConfInt = NaN;
                    self.simMaxRelErr = NaN;                        
                otherwise % currently used only by JMT
                    self.simConfInt = 0.99;
                    self.simMaxRelErr = 0.03;
            end
            self.disabled = 0;
            self.transient = false;
            switch type
                case {Perf.TranQLen, Perf.TranTput, Perf.TranUtil}
                    self.transient = true;
            end
        end
    end
    
    methods
        function self = setTran(self, bool)
            self.transient = bool;
        end
        
        function bool = isTran(self)
            bool = self.transient;
        end
        
        function bool = isDisabled(self)
            bool = self.disabled;
        end
        
        function self = disable(self)
            self.disabled = 1;
        end
        
        function self = enable(self)
            self.disabled = 0;
        end
        
        function value = get(self, results, model)
            if self.disabled == 1
                value = NaN;
                return
            end
            switch results.solver
                case 'SolverJMT'
                    for i=1:length(results.metric)
                        if strcmp(results.metric{i}.class, self.class.name) && strcmp(results.metric{i}.measureType,self.type) && strcmp(results.metric{i}.station, self.station.name)
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
                otherwise % assume a LINE solver
                    if ~exist('model','var')
                        error('Wrong syntax, use PerfIndex.get(results,model).\n');
                    end
                    classnames = model.getClassNames();
                    stationnames = model.getStationNames();
                    i = findstring(stationnames,self.station.name);
                    r = findstring(classnames,self.class.name);
                    switch self.type
                        case Perf.Util
                            value = results.Avg.U(i,r);
                        case Perf.SysRespT
                            value = results.Avg.C(i,r);
                        case Perf.SysTput
                            value = results.Avg.X(i,r);
                        case Perf.RespT
                            value = results.Avg.R(i,r);
                        case Perf.Tput
                            value = results.Avg.T(i,r);
                        case Perf.QLen
                            value = results.Avg.Q(i,r);
                        case Perf.TranTput
                            %results.TranAvg.T{i,r}.Name = sprintf('Throughput (station %d, class %d)',i,r);
                            %results.TranAvg.T{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.TranAvg.T{i,r};
                        case Perf.TranUtil
                            %results.TranAvg.U{i,r}.Name = sprintf('Utilization (station %d, class %d)',i,r);
                            %results.TranAvg.U{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.TranAvg.U{i,r};
                        case Perf.TranQLen
                            %results.TranAvg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.TranAvg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.TranAvg.Q{i,r};
                    end
            end
        end
    end
end

