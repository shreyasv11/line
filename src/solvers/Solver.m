classdef Solver < handle
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    
    properties
        options;
        name;
        model;
        result; % last result
    end
    
    methods (Hidden)
        %Constructor
        function self = Solver(model, name, options)
            if ~exist('options','var')
                options = self.defaultOptions();
            end
            self.model = model;
            self.name = name;
            self.options = options;
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function bool = supports(self,model) % true if model is supported by the solver
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
        function runtime = run(self) % generic method to run the solver
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
        end
    end
    
    methods
        function out = getName(self)
            out = self.name;
        end
        
        % this method is meant to be over-ridden by subclasses
        function options = getDefaultOptions(self)
            options = Solver.defaultOptions;
        end
    end
    
    methods
        
        function checkOptions(self, disabledChecks)
            if strcmp(self.options.method,'exact')
                if ~self.model.hasProductFormSolution
                    error('The model does not have a product-form solution, hence exact solution is not possible.');
                end
            end
        end
        
        function results = getResults(self)
            results = self.result;
        end
        
        function bool = hasResults(self)
            bool = ~isempty(self.result);
        end
        
        function options = getOptions(self)
            options = self.options;
        end
        
        function reset(self)
            self.result = [];
        end
        
        function self = setOptions(self, options)
            defaultOptions = self.defaultOptions;
            optList = Solver.listValidOptions();
            for l=1:length(optList)
                if ~isfield(options,optList{l})
                    options.(optList{l}) = defaultOptions.(optList{l});
                end
            end
            self.options = options;
        end
    end
    
    methods (Static)        
        
        function bool = isAvailable()
            % to be over-ridden by classes depending on external solvers
            bool = true;
        end
        
        function bool = isJavaAvailable()
            bool = true;
            if ispc % windows
                [~,ret] = dos('java -version');
                if strfind(ret,'not recognized') %#ok<STRIFCND>
                    bool = false;
                end
            else %linux
                [~,ret] = unix('java -version');
                if strfind(ret,'command not found') %#ok<STRIFCND>
                    bool = false;
                end
            end
        end
        
        function fun = accurateStiffOdeSolver(self)
			    if isoctave
				    %fun = @ode15s;
            fun = @lsode;
			    else
            fun = @ode15s;
			    end
        end
        
        function fun = accurateOdeSolver(self)
			    if isoctave
				    %fun = @ode15s;
            fun = @lsode;
			    else
            fun = @ode45;
			    end
        end
        
        function fun = fastStiffOdeSolver(self)
			    if isoctave
				    %fun = @ode15s;
            fun = @lsode;
			    else
				    fun = @ode23s;
			    end
        end
        
        function fun = fastOdeSolver(self)
			    if isoctave
				    %fun = @ode15s;
            fun = @lsode;
			    else
				    fun = @ode23s;
			    end
        end
        
        %         function solver = suggestAnalytical(model)
        %             qn = model.getStruct;
        %             modelFeat =  model.getUsedLangFeatures.list;
        %             solvers{1} = SolverMVA(model);
        %             solvers{2} = SolverFluid(model);
        %             solvers{3} = SolverMAM(model);
        %             solvers{4} = SolverNC(model);
        %
        %             featUsed = model.getUsedLangFeatures();
        %
        %             for s=1:length(solvers)
        %                 features{s,1} = solvers{s}.getFeatureSet;
        %                 supports(s) = SolverFeatureSet.supports(features{s,1}, featUsed);
        %             end
        %         end
        
        function optList = listValidOptions()
            optList = {'cache','cutoff','force','init_sol','iter_max','iter_tol','tol', ...
                'keep','method','odesolvers','samples','seed','stiff', ...
                'timespan','verbose'};
        end
        
        function bool = isValidOption(optName)
            bool = any(cell2mat(findstring(optName, Solver.listValidOptions()))==1);
        end
        
        function options = defaultOptions()
            options = struct();
            options.cache = true;
            options.cutoff = Inf;
            options.force = false;
            options.init_sol = [];
            options.iter_max = 10;
            options.iter_tol = 1e-4; % convergence tolerance to stop iterations
            options.tol = 1e-4; % tolerance for all other uses
            options.keep = false;
            options.method = 'default';
            odesfun = struct();
            odesfun.fastOdeSolver = Solver.fastOdeSolver;
            odesfun.accurateOdeSolver = Solver.accurateOdeSolver;
            odesfun.fastStiffOdeSolver = Solver.fastStiffOdeSolver;
            odesfun.accurateStiffOdeSolver = Solver.accurateStiffOdeSolver;
            options.odesolvers = odesfun;
            if isoctave
            options.samples = 5e3;
            else
            options.samples = 1e4;
            end
            %options.seed = 23000;
            options.seed = randi([1,1e6]);
            options.stiff = true;
            options.timespan = [Inf,Inf];
            options.verbose = 1;
        end
        
        function options = parseOptions(varargin, defaultOptions)
            if isempty(varargin)
                options = defaultOptions;
            elseif isstruct(varargin{1})
                options = varargin{1};
            elseif ischar(varargin{1})
                options = defaultOptions;
                for v=1:2:length(varargin)
                    if Solver.isValidOption(varargin{v})
                        options.(varargin{v}) = varargin{v+1};
                    else
                        warning('Option "%s\" does not exist. Ignoring.',varargin{v});
                    end
                end
            else
                error('Invalid parameter.');
            end
        end
        
        function solvers = getAllSolvers(model, options)
            if ~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            solvers{end+1} = SolverCTMC(model, options);
            solvers{end+1} = SolverJMT(model, options);
            solvers{end+1} = SolverSSA(model, options);
            solvers{end+1} = SolverFluid(model, options);
            solvers{end+1} = SolverMAM(model, options);
            solvers{end+1} = SolverMVA(model, options);
            solvers{end+1} = SolverNC(model, options);
        end
        
        function solvers = getAllFeasibleSolvers(model, options)
            if ~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            if SolverCTMC.supports(model)
                solvers{end+1} = SolverCTMC(model, options);
            end
            if SolverJMT.supports(model)
                solvers{end+1} = SolverJMT(model, options);
            end
            if SolverSSA.supports(model)
                solvers{end+1} = SolverSSA(model, options);
            end
            if SolverFluid.supports(model)
                solvers{end+1} = SolverFluid(model, options);
            end
            if SolverMAM.supports(model)
                solvers{end+1} = SolverMAM(model, options);
            end
            if SolverMVA.supports(model)
                solvers{end+1} = SolverMVA(model, options);
            end
            if SolverNC.supports(model)
                solvers{end+1} = SolverNC(model, options);
            end
        end
        
        function solver = get(model, varargin)
            options = Solver.parseOptions(varargin, Solver.defaultOptions);
            switch options.method
                case {'default','auto'}
                    if strcmp(options.method,'auto'), options.method='default'; end
                    solver = SolverAuto(model, options);
                case {'ctmc','ctmc.gpu','gpu'}
                    if strcmp(options.method,'ctmc'), options.method='default'; end
                    options.method = erase(options.method,'ctmc.');
                    solver = SolverCTMC(model, options);
                case {'mva','mva.exact','amva','mva.amva'}
                    if strcmp(options.method,'mva'), options.method='default'; end
                    options.method = erase(options.method,'mva.');
                    solver = SolverMVA(model, options);
                case {'ssa','ssa.serial.hash','ssa.serial','ssa.para','ssa.parallel','serial.hash','serial','para','parallel'}
                    if strcmp(options.method,'ssa'), options.method='default'; end
                    options.method = erase(options.method,'ssa.');
                    solver = SolverSSA(model, options);
                case {'jmt','jsim','jmva','jmva.mva','jmva.recal','jmva.comom','jmva.chow','jmva.bs','jmva.aql','jmva.lin','jmva.dmlin','jmva.ls',...
                        'jmt.jsim','jmt.jmva','jmt.jmva.mva','jmt.jmva.recal','jmt.jmva.comom','jmt.jmva.chow','jmt.jmva.bs','jmt.jmva.aql','jmt.jmva.lin','jmt.jmva.dmlin','jmt.jmva.ls'}
                    if strcmp(options.method,'jmt'), options.method='default'; end
                    options.method = erase(options.method,'jmt.');
                    solver = SolverJMT(model, options);
                case 'fluid'
                    if strcmp(options.method,'fluid'), options.method='default'; end
                    options.method = erase(options.method,'fluid.');
                    solver = SolverFluid(model, options);
                case 'mam'
                    if strcmp(options.method,'mam'), options.method='default'; end
                    options.method = erase(options.method,'mam.');
                    solver = SolverMAM(model, options);
                case {'mm1','mg1','gig1','gig1.kingman','gig1.gelenbe','gig1.heyman','gig1.kimura','gig1.allen','gig1.kobayashi','gig1.klb','gig1.marchal','gig1.myskja','gig1.myskja.b','gm1'}
                    solver = Library(model, options);                    
            end
        end
    end
end