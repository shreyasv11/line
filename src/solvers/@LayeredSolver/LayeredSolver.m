classdef LayeredSolver < Solver
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods (Hidden)
        function self = LayeredSolver(model, name, options)
            self = self@Solver(model,name);
            if exist('options','var'), self.setOptions(options); end
            if ~isa(model,'LayeredNetwork')
                error('Model is not a LayeredNetwork.');
            end
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function bool = supports(self, model) % true if model is supported by the solver
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function [QN,UN,RN,TN] = getAvg(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods
        function [AvgTable,QT,UT,RT,TT] = getAvgTable(self, wantLQNSnaming)
            if ~exist('wantLQNSnaming','var')
                wantLQNSnaming = false;
            end
            [QN,UN,RN,TN] = self.getAvg();
            Node = self.model.getGraph.Nodes.Node;
            Objects = self.model.getGraph.Nodes.Object;
            O = length(Objects);
            NodeType = cell(O,1);
            for o=1:O
                NodeType{o,1} = class(Objects{o});
            end
            if wantLQNSnaming
                utilization = QN;
                QT = Table(Node,utilization);
                procUtilization = UN;
                UT = Table(Node,procUtilization);
                phase1ServiceTime = RN;
                RT = Table(Node,phase1ServiceTime);
                throughput = TN;
                TT = Table(Node,throughput);
                AvgTable = Table(Node, NodeType, utilization, procUtilization, phase1ServiceTime, throughput);
            else
                QLen = QN;
                QT = Table(Node,QLen);
                Util = UN;
                UT = Table(Node,Util);
                RespT = RN;
                RT = Table(Node,RespT);
                Tput = TN;
                TT = Table(Node,Tput);
                AvgTable = Table(Node, NodeType, QLen, Util, RespT, Tput);
            end
        end
    end
    
    methods (Static)
        % ensemble solver options
        function options = defaultOptions()
            options = struct();
            options.method = 'default';
            options.init_sol = [];
            options.iter_max = 100;
            options.iter_tol = 1e-4;
            options.tol = 1e-4;
            options.verbose = 0;
        end
    end
end
