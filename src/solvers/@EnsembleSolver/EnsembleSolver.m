classdef EnsembleSolver < Solver
    % Abstract class for solvers applicable to Ensemble models 
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        ensemble;
        solvers;
        results;
    end
    
    methods (Hidden)
        function self = EnsembleSolver(model, name, options)
            self = self@Solver(model, name);
            if exist('options','var')
                self.setOptions(options);
            else
                self.setOptions(EnsembleSolver.defaultOptions);
            end
            self.ensemble = model.getEnsemble;
            self.solvers = {};
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function bool = supports(self, model) % true if model is supported by the solver
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function [QN,UN,RT,TT] = getAvg(self)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end        
        function init(self) % operations before starting to iterate
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function pre(self, it) % operations before an iteration
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function [results, runtime] = analyze(self, e) % operations within an iteration
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function post(self, it) % operations after an iteration
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function finish(self) % operations after interations are completed
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function bool = converged(self, it) % convergence test at iteration it
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods % default implementations
        function submodels = list(self, it) % submodels to be considered at iteration it
            submodels = 1:self.getNumberOfModels;
        end
        
        function it = getIteration(self)
            it = size(results,1);
        end
    end
    
    methods
        function solver = getSolver(self, e) % solver for ensemble model e
            solver = self.solvers{e};
        end
        
        % setSolver(solvers) : solver cell array is stored as such
        % setSolver(solver) : solver is assigned to all stages
        % setSolver(solver, e) : solver is assigned to stage e
        function solver = setSolver(self, solver, e)
            if iscell(solver)
                self.solvers = solver;
            else
                if ~exist('e','var')
                    for e=1:self.getNumberOfModels
                        self.solvers{e} = solver;
                    end
                else
                    self.solvers{e} = solver;
                end
            end
        end
        
        function E = getNumberOfModels(self)
            E = length(self.ensemble);
        end
        
        function [runtime, sruntime, results] = run(self)
            T0 = tic;
            it = 0;
            options = self.options;
            E = self.getNumberOfModels();
            results = cell(1,E);
            sruntime = zeros(1,E); % solver runtimes
            self.init();
            switch options.method
                case {'default','serial'}
                    while ~self.converged(it) & it < options.iter_max
                        it = it + 1;
                        self.pre(it);
                        sruntime(it,1:E) = 0;
                        for e = self.list(it)
                            [self.results{it,e}, solverTime] = self.analyze(it,e);
                            sruntime(it,e) = sruntime(it,e) + solverTime;
                        end
                        self.post(it);
                    end
                case {'para'}
                    %                     while ~self.converged(it) & it < options.iter_max
                    %                         it = it + 1;
                    %                         self.pre(it);
                    %                         sruntime(it,1:E) = 0;
                    %                         parfor e = self.list(it)
                    %                             [results{it,e}, solverTime] = self.run(it,e);
                    %                             sruntime(it,1+e) = sruntime(it,1+e) + solverTime;
                    %                         end
                    %                         for e=1:E % cannot be put within parfor
                    %                             self.results{it,e} = results{it,e};
                    %                         end
                    %                         self.post(it);
                    %                     end
            end
            self.finish();
            runtime = toc(T0);
        end
        
    end
    
    methods (Static)
        % ensemble solver options
        function options = defaultOptions()
            options = Solver.defaultOptions;
            options.method = 'default';
            options.init_sol = [];
            options.iter_max = 100;
            options.iter_tol = 1e-4;
            options.tol = 1e-4;
            options.verbose = 0;
        end
    end
end
