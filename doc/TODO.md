**SHOULD DO**
* Bug: test_self_loop.m, self-loop on ref station gives wrong utilization
* Remove transient handles
* Add FG-type inference system, with demand estimation methods
* Define performance metrics on the events and logger in SSA, defined them as classes so that later on we can do inference
* DRA and ETAQA in MAM
* BPMN importer.
* G-net
* Kingman-Kollerstrom approximation
* Bound Solver, with Mascots04 and QR bounds
* Functions to remove/update classes or stations (requires class re-indexing?)
* Check RAND AMVA with multi-server, add RAND to Fluid and NC
* Add a wrapper Solver to DiffLQN (do not release?
* Finish dump to SRVN format
* Integrate old ERandSolver
* Extract counting process and infinitesimal generator from simulation
* Bug: model.getLinkedRoutingMatrix() does not work with example_closed
* Sanitize routing. Add Disabled routing to JMT.
* Bug: SEPT and LEPT seem not to work right unless the sched weights are set explicitly.
* See 'oqn-14-sparse-fcfs.jsimg' where one of the stations is unreachable, the output to JMT does not create the link.
* force requires to re-evaluate the CTMC solution many times
* Do XML file to instantiate LINE models, or at least solve jsimgraph models

**RESEARCH TOPICS**
* Chain hierarchies, i.e., what if a class has a family of subclasses whose results should be aggregated in the same way as the class results are aggregated into chain results? In classic multichains there is a flat unconstrained  relationship among classes. Here instead we talk of bringing forward a vector of class state and routing could depend on such state. 
* Non-exp arrivals in open models and AMVA
* Fluid for open since #servers cannot be scaled at EXT node
* Class-switching in open models represented as closed models, how to loop-back correctly so that the P matrix gives the right weakly connected components in the presence of non-renewal open arrivals, A->B->(A or C), ...
* Definition of path metrics
* RAND scheduling, somewhat interesting state-space representation in-between PS and FCFS. Little is known for non-exp service. Interesting connection by Borst to DPS queues in open queueing systems.

**NEW FEATURES - SLOW**
* Add notion of replicas
* Add fork-join feature. Important to decide in the process if we need a concept of "Fork-region" or is it best to keep as in JMT. How would multiple fork regions interact if they overlap?
* Give the ability to express constraints on performance measures and automatically generate an optimization program with fmincon or ga. Obtain this by modifying YALMIP?
* Add ability to specify a parameter as "Prior" and a function for the solver to generate a posterior metric
* Define a workflow class based on the current LQN abstraction, checking also the constructs that are available in BPMN and the future QPN needs. 
* reliability analysis metrics: mark some states in the Environment as failed and define consequently MTTF, MTTR,
* add LPS scheduling
* add a MAM solver, based on DRA? Can MAM provide a natural way to do workflows, alternative to PNs? The motification could be that we represent only moments of the synchronization, not the full state space.
* add priorities. reuse aqlclhol_highcv implementation for AMVA and prio-fluid work with Mirco.
* add MCMC solver? based on ode_rates of the fluid or CTMC rates, sampling of G
* plug-in the existing work done on MAPQNs and MAPQNs-FC.
* add Bottleneck analysis (ABA, bounds, asymptotics etc)
* add P2C, PKC routing

** CODE MIGRATION **
* MASCOTS 2007
* MAPQNs: LR, QR, FC case, MAP-AMVA, 
* ETAQA
* KPC, M3A
* PDP robust regression
* CMVA / load dependent
* Bayesian expansion
* Entropy methods (QRF framework)
* ICPE 2012
* TSE 2012
* Tandem NSMC 2012
* AutoCAT
* IFIP Performance 2013 policy
* OptiSPOT
* TP-AMVA Karsten
* TSE 2015: likelihood response times
* Bayesian optimization code

* TODO: 
autoload (auto­detect input)
accept preferences like PreferSlowButMoreAccurate, preferLowMemFootPrint),   
decision tree or neural network to choose best method

* Useful MATLAB library functions:
codeCompatibilityReport
inputParser
