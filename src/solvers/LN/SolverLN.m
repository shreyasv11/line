classdef SolverLN < LayeredNetworkSolver & EnsembleSolver
    % LINE native solver for layered networks.
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods
        function self = SolverLN(model,solverFactory,varargin)
            self = self@LayeredNetworkSolver(model, mfilename);
            self@EnsembleSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            self.model.initDefault;
            self.ensemble = self.model.getEnsemble();
            for e=1:self.getNumberOfModels
                self.setSolver(solverFactory(self.ensemble{e}),e);
            end
        end
        
        function bool = converged(self, it) % convergence test at iteration it
            bool = false;
            if it>1
                maxIterErr = 0;
                for e=1:size(self.results,2)
                    maxIterErr = max([maxIterErr, nanmax(abs(1 - self.results{end,e}.RespT ./ self.results{end-1,e}.RespT))]);
                end
                %                maxIterErr
                if it > 1 && self.options.verbose == 2
                    fprintf(1, sprintf('\nSolverLN error is: %f',maxIterErr));
                end
                if maxIterErr < 1e-5 && self.options.verbose
                    fprintf(1, sprintf('\nSolverLN completed in %d iterations.\n',size(self.results,2)));
                    bool = true;
                end
            end
        end
        
        function init(self) % operations before starting to iterate
            %nop
        end
        
        function pre(self, it) % operations before an iteration
            %nop
        end
        
        function [result, runtime] = analyze(self, it, e)
            T0 = tic;
            self.solvers{e}.reset();
            result = self.solvers{e}.getAvgTable();
            runtime = toc(T0);
        end
        
        function post(self, it) % operations after an iteration
            for post_it = 1:2 % do elevator up and down
                self.model.updateParam({self.results{it,:}});
            end
            self.ensemble = self.model.refreshLayers(); % update Network objects in ensemble
        end
        
        function finish(self) % operations after interations are completed
            %nop
        end
        
        function [QN,UN,RN,TN] = getAvg(self,~,~,~,~)
            self.run(); % run iterations
            lqnGraph = self.model.getGraph;
            Avg = self.model.param;
            % At this point the Avg data structure includes only the
            % fundamental perf indexes that uniquely determine a valid LQN.
            % We now derive the other perf indexes
            for edge=1:height(lqnGraph.Edges)
                if lqnGraph.Edges.Type(edge) == 1 % add contribution of sync-calls
                    syncSource = lqnGraph.Edges.EndNodes{edge,1};
                    aidx = findstring(lqnGraph.Nodes.Name,syncSource);
                    if lqnGraph.Edges.Weight(edge) >= 1
                        Avg.Nodes.RespT(aidx) = Avg.Nodes.RespT(aidx) +  Avg.Edges.RespT(edge) * lqnGraph.Edges.Weight(edge);
                    else
                        Avg.Nodes.RespT(aidx) = Avg.Nodes.RespT(aidx) +  Avg.Edges.RespT(edge);
                    end
                end
            end
            % - qlen is respT * tput
            % - qlen of task is sum of qlen of its entries
            % - tput of task is sum of tput of its entries
            % - util of entry is sum of util of its activities
            Avg.Nodes.QLen = Avg.Nodes.RespT .* Avg.Nodes.Tput;
            Avg.Nodes.Util = lqnGraph.Nodes.D .* Avg.Nodes.Tput;
            procPos = strcmp(lqnGraph.Nodes.Type,'P');
            Avg.Nodes.QLen(procPos) = NaN;
            Avg.Nodes.RespT(procPos) = NaN;
            Avg.Nodes.Tput(procPos) = NaN;
            taskPos = strcmp(lqnGraph.Nodes.Type,'R') | strcmp(lqnGraph.Nodes.Type,'T');
            for tidx = find(taskPos)'
                entriesOfTask = self.model.listEntriesOfTask(tidx);
                for e = 1:length(entriesOfTask)
                    Avg.Nodes.Tput(tidx) = 0;
                end
                for e = 1:length(entriesOfTask)
                    eidx = self.model.getNodeIndex(entriesOfTask{e});
                    Avg.Nodes.QLen(tidx) = Avg.Nodes.QLen(tidx) + Avg.Nodes.QLen(eidx);
                    Avg.Nodes.Tput(tidx) = Avg.Nodes.Tput(tidx) + Avg.Nodes.Tput(eidx);
                    actOfEntry = self.model.listActivitiesOfEntry(entriesOfTask{e});
                    Avg.Nodes.Util(eidx) = 0;
                    for a = 1:length(actOfEntry)
                        aidx = self.model.getNodeIndex(actOfEntry{a});
                        Avg.Nodes.Util(eidx) = Avg.Nodes.Util(eidx) + Avg.Nodes.Util(aidx);
                    end
                    Avg.Nodes.Util(tidx) = Avg.Nodes.Util(tidx) + Avg.Nodes.Util(eidx);
                end
                pidx = self.model.getNodeIndex(lqnGraph.Nodes.Proc{tidx});
                Avg.Nodes.Util(pidx) = Avg.Nodes.Util(pidx) + Avg.Nodes.Util(tidx);
            end
            Avg.Nodes.RespT(taskPos) = NaN;
            QN =  Avg.Nodes.QLen;
            UN =  Avg.Nodes.Util;
            TN =  Avg.Nodes.Tput;
            RN =  Avg.Nodes.RespT;
        end
    end
    
    methods (Static)
        function [bool, featSupported] = supports(model)
            % todo
            bool = true;
        end
    end
    
    methods (Static)
        function options = defaultOptions(self)
            options = EnsembleSolver.defaultOptions();
            options.timespan = [Inf,Inf];
            options.keep = false;
            options.verbose = 2;
        end
    end
end
