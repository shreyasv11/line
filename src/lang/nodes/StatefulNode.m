classdef StatefulNode < Node
    % An abstract class for nodes with a state
    %
    % Copyright (c) 2012-2019, Imperial College London
    % All rights reserved.
    
    properties
        state;
        statePrior;
        space;
    end
    
    methods(Hidden)
        %Constructor
        function self = StatefulNode(name)
            % SELF = STATEFULNODE(NAME)
            self@Node(name);
            self.statePrior = [];
            self.state = [];
            self.space = {};
        end
        
        function prior = getStatePrior(self)
            % PRIOR = GETSTATEPRIOR(SELF)
            % prior(j) = probability that the initial state is state(j)
            prior = self.statePrior;
        end
        
        function self = setStatePrior(self, prior)
            % SELF = SETSTATEPRIOR(SELF, PRIOR)
            % the prior is marginalized on the station state and thus
            % assumed independent of the priors for other stations
            self.statePrior = prior(:); % we do not normalize to allow the user to manually run a model for each point of an external prior
            if size(self.statePrior,1) ~= size(self.state,1)
                error('The prior probability vector must have the same rows of the station state vector.');
            end
        end
        
        function self = setState(self, state)
            % SELF = SETSTATE(SELF, STATE)
            % state can be stacked in a matrix of states, a state space
            self.state = state;
            if size(self.statePrior,1) ~= size(self.state,1)
                %self.setStatePrior(ones(size(state,1),1)/size(state,1));
                initPrior = zeros(size(state,1),1); initPrior(1) = 1;
                self.setStatePrior(initPrior);
            end
        end
        
        function state = getState(self)
            % STATE = GETSTATE(SELF)
            state = self.state;
        end
        
        function self = setStateSpace(self, space)
            % SELF = SETSTATESPACE(SELF, SPACE)
            self.space = space;
            %            mState.getHash = memoize(@(x) self.State.getHash(x));
        end
        
        function self = resetStateSpace(self)
            % SELF = RESETSTATESPACE(SELF)
            self.space = {};
        end
        
    end
    
    
end
