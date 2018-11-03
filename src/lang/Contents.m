% LINE modelling language.
%
% Static classes
%   Perf                -	Available performance measures (throughput, utilization, ...).
%   DropRule            -	Available drop rules (drop, BAS blocking, ...). 
%   JoinStrategy        -	Available join strategies (standard, quorum, ...).
%   SchedPolicy         -	Available scheduling policies (preemptive, non-preemptive, ...).
%   SchedStrategy       -	Available scheduling strategies (FCFS, LCFS, ...).
%   RoutingStrategy     -	Available routing strategies (join-short-queue, ...).
%   ServiceStrategy     -	Available service strategies (load-dependent, ...).
%   NodeType
%
% Model representations
%   Network               -	Stochastic network specification.
%   LayeredNetwork - Layered network specification
%   PerfIndex           -	Performance index to be analyzed by a solver.
%   QN - Queueing network data structure
%   QNCox - QN with coxian service or interarrival times
%   QN - QNCox with class switching
%   Ensemble - Ensemble model
%
% Class specification
%   JobClass       -	Abstract class for a job class.
%   OpenClass           -	Open job class
%   ClosedClass         -	Closed job class
%   Chain - Group of classes formjng a chain
%   ClassSwitchSection  -   Section for a ClassSwitch node.
%   ClassSwitch         -	Node that alters the class of a transiting job.
%
% Event and state specification
%   Event				- 	Generic event
%   State/* - Functions for state space modeling
%   Prior - Prior on a state
%
% Service/arrival processes
%   Distribution        -	Abstract class for distributions.
%   PointProcess        -	Abstract class for point processes.
%	Cox2				- 	Cox-2 distribution.
%   Det 		        -	Deterministic distribution.
%   Erlang              -	Erlang distribution.
%   Exp                 -	Exponential distribution.
%   Gamma               -	Gamma distribution.
%   HyperExp            -	Hyper-exponential distribution.
%   MMPP2               -	Markov-modulated Poisson process with 2-state.
%   Pareto              -	Pareto distribution.
%   Trace               -   Trace loader.	
%   Uniform             -	Uniform distribution.
%
% Nodes
%   Node                -	Abstract class for node in the model.
%   Logger          -	Node that logs job transit
%   Router          -	Job router
%   Sink            -	Open class job sink
%   Source          -	Open class job source
%
% Stations
%   Station             -	A class of nodes where jobs can station.
%   DelayStation        -	Station representing a pure delay (no queueing) 
%   ForkStation         -	Station that forks incoming jobs
%   JoinStation         -	Station that joins incoming jobs.
%   Queue     -	An ordinary queueing station.
%
% Sections
%   Section             -	Abstract class for node section.
%   Delay               -	Service section for a DelayStation.
%   Fork                -	Service section for a ForkNode.
%   Join                -	Service section for a JoinNode.
%   LogTunnel           -	Service section for a LogNode.
%   SharedServer            -	Processor-sharing service section.
%   Queue               -	Queue input section.
%   RandomSource        -	Source output section.
%   Dispatcher              -	Abstract class for station's output section.
%   Server              -	Service section for a Queue.
%   ServiceTunnel       -	Service section that do not serve the job.
%
% Layered networks
%    Activity - Activity node within an entry
%    ActivityPrecedence - Activity graph within an entry
%    Entry - Entry within a task
%    Processor - Hardware processor
%    Task - Task or pseudo-task running on processor