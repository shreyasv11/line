% LINE state modeling and state space generation
%
%  afterEvent             - given a state and an event, generate the resulting states
%	afterEventHashed       - same as stateAfterEvent, but states are hashed in both input and output
% afterEventHashedOrAdd
% afterEventOrAdd
%	spaceClosedMulti            - state space of a closed multiclass network
%	spaceClosedMultiCS          - state space of a closed multiclass network with class-switching
%	spaceClosedSingle           - state space of a closed single class network
%	decorate               - concatenate state spaces
%	fromMarginal           - generate states that have identical marginal probability
%	fromMarginalBounds     - generate states that have marginals lying between upper and lower bounds
%	fromMarginalAndRunning	- generate states that have identical marginals and number of running jobs, irrespectively of the service phase in which they currently run
%	fromMarginalAndStarted	- generate states that have identical marginals and number of running jobs, all assumed to be in service phase 1
%	hash - hash a state vector according to the local state-space of the station
% hashOrAdd
% isValid
%	toMarginal - return marginal probabilities associated to given state
