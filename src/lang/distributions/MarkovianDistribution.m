classdef MarkovianDistribution < ContinuousDistrib
    % An astract class for Markovian distributions
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    methods (Hidden)
        function self = MarkovianDistribution(name, numParam)
            % SELF = MARKOVIANDISTRIBUTION(NAME, NUMPARAM)
            
            % Abstract class constructor
            self@ContinuousDistrib(name, numParam, [0,Inf]);
        end
    end
    
    methods
        function X = sample(self, n)
            % X = SAMPLE(N)
            
            % Get n samples from the distribution
            if ~exist('n','var'), n = 1; end
            X = map_sample(self.getRepresentation,n);
        end
        
        function EXn = getRawMoments(self, n)
            % EXN = GETRAWMOMENTS(N)
            
            if ~exist('n','var'), n = 3; end
            PH = self.getRepresentation;
            EXn = map_moment(PH,1:n);
        end
        
        function MEAN = getMean(self)
            % MEAN = GETMEAN()
            
            MEAN = map_mean(self.getRepresentation);
        end
        
        function SCV = getSCV(self)
            % SCV = GETSCV()
            % Get the squared coefficient of variation of the distribution (SCV = variance / mean^2)
            SCV = map_scv(self.getRepresentation);
        end
        
        function SKEW = getSkewness(self)
            % SKEW = GETSKEWNESS()
            
            SKEW = map_skew(self.getRepresentation);
        end
        
        function Ft = evalCDF(self,t)
            % FT = EVALCDF(SELF,T)
            
            % Evaluate the cumulative distribution function at t
            % AT T
            
            Ft = map_cdf(self.getRepresentation,t);
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        
        function update(self,varargin)
            % UPDATE(SELF,VARARGIN)
            
            % Update parameters to match given moments
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
            
        end
        
        function updateMean(self,MEAN)
            % UPDATEMEAN(SELF,MEAN)
            
            % Update parameters to match a given mean
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
            
        end
        
        function updateRate(self,RATE)
            % UPDATERATE(SELF,RATE)
            
            % Update rate
            self.updateMean(1/RATE);
        end
        
        function self = updateMeanAndVar(self, MEAN, VAR)
            % SELF = UPDATEMEANANDVAR(MEAN, VAR)
            
            % Update distribution with given mean and variance
            SCV = VAR / MEAN^2;
            ex = self.fitMeanAndSCV(MEAN,SCV);
        end
        
        function self = updateMeanAndSCV(self, MEAN, SCV)
            % SELF = UPDATEMEANANDSCV(MEAN, SCV)
            
            % Update distribution with given mean and squared coefficient of
            % variation (SCV=variance/mean^2)
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
            
        end
        
        function phases = getNumberOfPhases(self)
            % PHASES = GETNUMBEROFPHASES()
            
            % Return number of phases in the distribution
            PH = self.getRepresentation;
            phases = length(PH{1});
        end
        
        function PH = getRepresentation(self)
            % PH = GETREPRESENTATION()
            
            % Return the renewal process associated to the distribution
            error('An abstract method was invoked. The function needs to be overridden by a subclass.');
            
        end
        
        function L = evalLaplaceTransform(self, s)
            % L = EVALLAPLACETRANSFORM(S)
            
            % Evaluate the Laplace transform of the distribution function at t
            % AT T
            
            PH = self.getRepresentation;
            pie = map_pie(PH);
            A = PH{1};
            e = ones(length(pie),1);
            L = pie*inv(s*eye(size(A))-A)*(-A)*e;
        end
        
        function plot(self)
            % PLOT()
            
            PH = self.getRepresentation;
            s = []; % source node
            t = []; % dest node
            w = []; % edge weight
            c = []; % edge color
            l = {}; % edge label
            for i=1:self.getNumberOfPhases
                for j=1:self.getNumberOfPhases
                    if i~=j
                        if PH{1}(i,j) > 0
                            s(end+1) = i;
                            t(end+1) = j;
                            w(end+1) = PH{1}(i,j);
                            c(end+1) = 0;
                            l{end+1} = num2str(w(end));
                        end
                    end
                    if PH{2}(i,j) > 0
                        s(end+1) = i;
                        t(end+1) = j;
                        w(end+1) = PH{2}(i,j);
                        c(end+1) = 1;
                        l{end+1} = num2str(w(end));
                    end
                end
            end
            G = digraph(s,t,w);
            p = plot(G,'EdgeColor','k','NodeColor','k','LineStyle','-','Marker','o','MarkerSize',4,'Layout','layered','EdgeLabel',l,'Direction','right');
            % highlight observable transitions in red
            highlight(p,s(c==1),t(c==1),'LineStyle','-','EdgeColor','r');
        end
    end
    
end

