## Table of Contents 
[**Solvers**](https://github.com/line-solver/line/wiki/Network-solvers#network-solvers)
- [Overview](https://github.com/line-solver/line/wiki/Network-solvers#overview)
   - [Available solvers](https://github.com/line-solver/line/wiki/Network-solvers#available-solvers)
- [Solution algorithms](https://github.com/line-solver/line/wiki/Network-solvers#solution-algorithms)
   - [`AUTO`](https://github.com/line-solver/line/wiki/Network-solvers#auto)
   - [`CTMC`](https://github.com/line-solver/line/wiki/Network-solvers#ctmc)
   - [`FLUID`](https://github.com/line-solver/line/wiki/Network-solvers#fluid)
   - [`JMT`](https://github.com/line-solver/line/wiki/Network-solvers#jmt)
   - [`MAM`](https://github.com/line-solver/line/wiki/Network-solvers#mam)
   - [`MVA`](https://github.com/line-solver/line/wiki/Network-solvers#mva)
   - [`NC`](https://github.com/line-solver/line/wiki/Network-solvers#nc)
   - [`SSA`](https://github.com/line-solver/line/wiki/Network-solvers#ssa)
- [Supported language features and options](https://github.com/line-solver/line/wiki/Network-solvers#supported-language-features-and-options)
   - [Solver features](https://github.com/line-solver/line/wiki/Network-solvers#solver-features)
   - [Class functions](https://github.com/line-solver/line/wiki/Network-solvers#class-functions)
   - [Scheduling strategies](https://github.com/line-solver/line/wiki/Network-solvers#scheduling-strategies)
   - [Statistical distributions](https://github.com/line-solver/line/wiki/Network-solvers#statistical-distributions)
   - [Solver options](https://github.com/line-solver/line/wiki/Network-solvers#solver-options)
- [Solver maintenance](https://github.com/line-solver/line/wiki/Network-solvers#solver-maintenance)

# Network solvers

## Overview

Solvers analyze objects of class `Network` to return average, transient,
distributions, or state probability metrics. A solver can implement one
or more <span>*methods*</span>, which although sharing a similar overall
solution strategy, they can differ significantly from each other in the
way this is actually implemented and on wether the final solution is
exact or approximate.

The `method` field in the options structure array passed to a solver can
be used to select the desired method, e.g., `options.method=’default’`
requires the solver to use default options, while
`options.method=’exact’` requires to solve the model exactly, if an
exact solution method is available.

In what follows, we describe the general characteristics and supported
model features for each solver available in
<span class="smallcaps">LINE</span> and their methods.

#### Available solvers

The following `Network` solvers are available within
<span class="smallcaps">Line</span> 2.0.0-ALPHA:

  - `AUTO`: This solver uses an algorithm to select the best solution
    method for the model under consideration, among those offered by the
    other solvers. Analytical solvers are always preferred to
    simulation-based solvers. This solver is implemented by the
    `SolverAuto` class.

  - `CTMC`: This is a solver that returns the exact values of the
    performance metrics by explicit generation of the continuous-time
    Markov chain (CTMC) underpinning the model. As the CTMC typically
    incurs state-space explosion, this solver can successfully analyze
    only small models. The <span>CTMC</span> solver is the only method
    offered within <span class="smallcaps">Line</span> that can return
    an exact solution on all Markovian models, all other solvers are
    either approximate or are simulators. This solver is implemented by
    the `SolverCTMC` class.

  - `FLUID`: This solver analyzes the model by means of an approximate
    fluid model, leveraging a representation of the queueing network as
    a system of ordinary differential equations (ODEs). The fluid model
    is approximate, but if the servers are all PS or INF, it can be
    shown to become exact in the limit where the number of users and the
    number of servers in each node grow to infinity \[[Perez et al. 2013](https://dl.acm.org/citation.cfm?id=2624969)\].
    This solver is implemented by the `SolverFluid` class.

  - `JMT`: This is a solver that uses a model-to-model transformation to
    export the <span class="smallcaps">Line</span> representation into a
    JMT simulation model \[[Bertoli et al. 2006](http://jmt.sourceforge.net/Papers/qest06jmt.pdf)\]. This solver can analyze also
    non-Markovian models, in particular those involving deterministic or
    Pareto distributions, or empirical traces. This solver is
    implemented by the `SolverJMT` class.

  - `MAM`: This is a matrix-analytic method solver, which relies on
    quasi-birth death (QBD) processes to analyze open queueing systems.
    This solver is implemented by the `SolverMAM` class.

  - `MVA`: This is a solver based on approximate and exact mean-value
    analysis. This solver is typically the fastest and offers very good
    accuracy in a number of situations, in particular models where
    stations have a single-server. This solver is implemented by the
    `SolverMVA` class.

  - `NC`: This solver uses a combination of methods based on the
    normalizing constant of state probability to solve a model. The
    underpinning algorithm are particularly useful to compute marginal
    and joint state probabilities in queueing network models. This
    solver is implemented by the `SolverNC` class.

  - `SSA`: This is a discrete-event simulator based on the CTMC
    representation of the model. The solver is implemented in MATLAB
    language and thus tends to offer lower speed than JMT, but the model
    execution can be easily parallelized using MATLAB’s
    <span>*spmd*</span> construct. This solver is implemented by the
    `SolverSSA` class.

## Solution algorithms

### `AUTO`

The `SolverAuto` class provides interfaces to the core solution
functions (e.g., `getAvg`, ...) that dynamically bind to one of the
other solvers implemented in <span class="smallcaps">Line</span>
(`CTMC`, `NC`, ...). It is often not possible to identify the best
solver without some performance results on the model, for example to
determine if it operates in light, moderate, or heavy-load regime.

Therefore, heuristics are used to identify a solver based on structural
properties of the model, such as based on the scheduling strategies used
at the stations as well as the number of jobs, chains, and classes. Such
heuristics, though, are independent of the core function called, thus it
is possible that the optimal solver does not support the specific
function called (e.g., `getTranAvg`). In such cases `SolverAuto`
determines what other solvers would be feasible and prioritizes them in
execution time order, with the fastest one on average having the higher
priority. Eventually, the solver will be always able to identify a
solution strategy, through at least simulation-based solvers such as
`JMT` or `SSA`.

### `CTMC`

The `SolverCTMC` class solves the model by first generating the
infinitesimal generator of the `Network` and then calling an appropriate
solver. Steady-state analysis is carried out by solving the global
balance equations defined by the infinitesimal generator. If the `keep`
option is set to true, the solver will save the infinitesimal generator
in a temporary file and its location will be shown to the user.

Transient analysis is carried out by numerically solving Kolmogorov’s
forward equations using MATLAB’s ODE solvers. The range of integration
is controlled by the `timespan` option. The ODE solver choice is the
same as for `SolverFluid`.

The CTMC solver heuristically limits the solution to models with no more
than 6000 states. The `force` option needs to be set to true to bypass
this control. In models with infinite states, such as networks with open
classes, the `cutoff` option should be used to reduce the CTMC to a
finite process. If specified as a scalar value, `cutoff` is the maximum
number of jobs that a class can place at an arbitrary station. More
generally, a matrix assignment of `cutoff` indicates to `LINE` that
`cutoff`(i,r) is the maximum number of jobs of class r that can
be placed at station i.

### `FLUID`

This solver is based on the system of fluid ordinary differential
equations for INF-PS queueing networks presented in \[[Perez et al. 2017](https://ieeexplore.ieee.org/document/7843645/)\].

The fluid ODEs are normally solved with the `’NonNegative’` ODE solver
option enabled. Four types of ODE solvers are used: *fast* or
*accurate*, the former only if `options.iter_tol`> 10^{-3}, and
*stiff* or *non-stiff*, depending on the value of `options.stiff`. The
default choice of solver is stored in the following static functions:

  - `Solver.accurateStiffOdeSolver`, set to MATLAB’s `ode15s`.

  - `Solver.accurateOdeSolver`, set to `ode45`.

  - `Solver.fastStiffOdeSolver`, set to `ode23s`.

  - `Solver.fastOdeSolver`, set to `ode23`.

ODE variables corresponding to an infinite number of jobs, as in the job
pool of a source station, or to jobs in a disabled class are not
included in the solution vector. These rules apply also to the
`options.init_sol` vector.

The solution of models with FCFS stations maps these stations into
corresponding PS stations where the service rates across classes are set
identical to each other with a service distribution given by a mixture
of the service processes of the service classes. The mixture weights are
determined iteratively by solving a sequence of PS models until
convergence. Upon initializing FCFS queues, jobs in the buffer are all
initialized in the first phase of the service.

### `JMT`

The class is a wrapper for the `JMT` simulation and consists of a
model-to-model transformation from the `Network` data structure into the
JMT’s input XML format (`.jsimg`) and a corresponding parser for JMT’s
results. In the transformation, artificial nodes will be automatically
added to the routing table to represent class-switching nodes used in
the simulator to specify the switching rules. One such class-switching
node is defined for every ordered pair of stations (i,j) such that
jobs change class in transit from i to j.

Upon invocation, the `JMT` JAR archive will be searched in the MATLAB
path and if unavailable automatically downloaded.

### `MAM`

This is a basic solver for some Markovian open queueing systems that can
be analyzed using matrix analytic methods. The solver at the moment is a
basic wrapper for the <span>BU tools</span> library for matrix-analytic
methods \[[Horvath et al. 2017](https://doi.org/10.4108/eai.25-10-2016.2266400)\]. At present, it is not possible to solve a queueing
network model using `SolverMAM`.

### `MVA`

The solver is primarily based on the Bard-Schweitzer approximate mean
value analysis (AMVA) algorithm (`options.method=’default’`), but also
offers and implementation of the exact MVA algorithm
(`options.method=’exact’`). Non-exponential service times in FCFS
nodes are treated using a M/G/1-type approximation. Multi-server FCFS is
dealt with using a slight modification of the Rolia-Sevcik
method \[[Rolia et al. 1995](https://dl.acm.org/citation.cfm?id=631178)\]. DPS queues are analyzed with a time-scale
separation method, so that for an incoming job of class r and weight
w_r, classes with weight w_s>= 5w_r are replaced by
high-priority classes that are analyzed using the standard MVA priority
approximation. Conversely the remaining classes are treated by weighting
the queue-length seen upon arrival in class seq r by the
correction factor w_s/w_r.

### `NC`

The `SolverNC` class implements a family of solution algorithms based on
the normalizing constant of state probability of product-form queueing
networks. Contrary to the other solvers, this method typicallly maps the
problem to certain multidimensional integrals, allowing the use of
numerical methods such as MonteCarlo sampling and asymptotic expansions
in their approximation.

### `SSA`

The `SolverSSA` class is a basic stochastic simulator for
continuous-time Markov chains. It reuses some of the methods that
underpin `SolverCTMC` to generate the network state space and
subsequently simulates the state dynamics by probabilistically choosing
one among the possible events that can incur in the system, according to
the state spaces of each of node in the network. For efficiency reasons,
states are tracked at the level of individual stations, and hashed. The
state space is not generated upfront, but rather stored during the
simulation, starting from the initial state. If the initialization of a
station generates multiple possible initial states, `SSA` initializes
the model using the first state found. The list of initial states for
each station can be obtained using the `getInitState` functions of the
`Network` class.

The `SSA` solver offers four methods: `’serial’` (default),
`’serial-hashed’`, `’parallel’`, and `’parallel-hashed’`. The serial
methods run on a single core, while the parallel methods run on
multicore via MATLAB’s `spmd` command. The `’hashed’` option requires
the solver to maintain in memory a hashed list of the node states, as
opposed to the joint state vector for the system. As a result, the
memory occupancy is lower, but the simulation tends to become slower on
models with nodes that have large state spaces, due to the extra cost
for hashing.

## Supported language features and options

### Solver features

Once a model is specified, it is possible to use the
`getUsedLangFeatures` function to obtain a list of the features of a
model. For example, the following conditional statement checks if the
model contains a FCFS node

    if (model.getUsedLangFeatures.list.SchedStrategy_FCFS)
    ...

Every <span class="smallcaps">LINE</span> solver implements the
`support` to check if it supports all language features used in a
certain model

    >> SolverJMT.supports(model)
    ans =
      logical
       1

It is possible to programmatically check which solvers are available for
a given model as follows

    >> Solver.getAllFeasibleSolvers(model)
    ans =
      1x6 cell array
        {1x1 SolverCTMC}    {1x1 SolverJMT}    {1x1 SolverSSA}    {1x1 SolverFluid}    {1x1 SolverMVA}    {1x1 SolverNC}

In the example, `SolverMAM` is not feasible for the considered model and
therefore not returned. Note that `SolverAuto` is never included in the
list returned by this methods since this is a wrapper for other solvers.

### Class functions

The table below lists the steady-state and transient analysis functions
implemented by the `Network` solvers. Since the features of the `AUTO`
solver are the union of the features of the other solvers, in what
follows it will be omitted from the description.

<table>
<caption>Solver support for scheduling strategies</caption>
<tbody>
<tr class="odd">
<td style="text-align: left;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><p><strong>Function</strong></p></td>
<td style="text-align: center;"><strong>Regime</strong></td>
<td style="text-align: center;"><code>CTMC</code></td>
<td style="text-align: center;"><code>FLUID</code></td>
<td style="text-align: center;"><code>JMT</code></td>
<td style="text-align: center;"><code>MAM</code></td>
<td style="text-align: center;"><code>MVA</code></td>
<td style="text-align: center;"><code>NC</code></td>
<td style="text-align: center;"><code>SSA</code></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvg</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgTable</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgChainTable</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgSys</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgSysTable</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgArvR</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgArvRChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgQLen</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgQLenChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgRespT</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgRespTChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgTput</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgTputChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getAvgUtil</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getAvgUtilChain</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getCdfRespT</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getProbState</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getProbStateSys</code></td>
<td style="text-align: center;">Steady-state</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getTranAvg</code></td>
<td style="text-align: center;">Transient</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getTranCdfPassT</code></td>
<td style="text-align: center;">Transient</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getTranCdfRespT</code></td>
<td style="text-align: center;">Transient</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="odd">
<td style="text-align: left;"><code>getTranState</code></td>
<td style="text-align: center;">Transient</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: left;"><code>getTranStateSys</code></td>
<td style="text-align: center;">Transient</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
</tbody>
</table>

<span id="TAB_solver_functions" label="TAB_solver_functions">\[TAB\_solver\_functions\]</span>

The functions listed above with the `Table` suffix (e.g., `getAvgTable`)
provide results in tabular format corresponding to the corresponding
core function (e.g., `getAvg`). The features of the core functions are
as follows:

  - `getAvg`: returns the mean queue-length, utilization, mean response
    time (for one visit), and throughput for each station and class.

  - `getAvgChain`: returns the mean queue-length, utilization, mean
    response time (for one visit), and throughput for every station and
    chain.

  - `getAvgSys`: returns the system response time and system throughput,
    as seen as the reference node, by chain.

  - `getCdfRespT`: returns the distribution of response times (for one
    visit) for the stations at steady-state.

  - `getProbState`: returns joint and marginal state probabilities for
    jobs of different classes for each station at steady-state.

  - `getProbStateSys`: returns joint probabilities for the system state
    for each class at steady-state.

  - `getTranAvg`: returns transient mean queue length, utilization and
    throughput for every station and chain from a given initial state.

  - `getTranCdfPassT`: returns the distribution of first passage times
    in transient regime.

  - `getTranCdfRespT`: returns the distribution of response times in
    transient regime.

  - `getTranState`: returns the transient marginal state for every
    stations and class from a given initial state.

  - `getTranStateSys`: returns the transient marginal system state from
    a given initial state.

### Scheduling strategies

The table below shows the supported scheduling strategies within
<span class="smallcaps">Line</span> queueing stations. Each strategy
belongs to a policy class: preemptive resume (`SchedPolicy.PR`) ,
non-preemptive (`SchedPolicy.NP`), non-preemptive priority
(`SchedPolicy.NPPrio`).

<table>
<caption>Solver support for scheduling strategies</caption>
<tbody>
<tr class="odd">
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: center;"><p><strong>Strategy</strong></p></td>
<td style="text-align: center;"><strong>Policy Class</strong></td>
<td style="text-align: center;"><code>CTMC</code></td>
<td style="text-align: center;"><code>FLUID</code></td>
<td style="text-align: center;"><code>JMT</code></td>
<td style="text-align: center;"><code>MAM</code></td>
<td style="text-align: center;"><code>MVA</code></td>
<td style="text-align: center;"><code>NC</code></td>
<td style="text-align: center;"><code>SSA</code></td>
</tr>
<tr class="odd">
<td style="text-align: center;">FCFS</td>
<td style="text-align: center;">NP</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">INF</td>
<td style="text-align: center;">NP</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">RAND</td>
<td style="text-align: center;">NP</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">SEPT</td>
<td style="text-align: center;">NP</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">SJF</td>
<td style="text-align: center;">NP</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: center;">HOL</td>
<td style="text-align: center;">NPPrio</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">PS</td>
<td style="text-align: center;">PR</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">DPS</td>
<td style="text-align: center;">PR</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">GPS</td>
<td style="text-align: center;">PR</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
</tbody>
</table>

<span id="TAB_solver_policies" label="TAB_solver_policies">\[TAB\_solver\_policies\]</span>

### Statistical distributions

The table below summarizes the current level of support for arrival and
service distributions within each solver. `Replayer` represents an
empirical trace read from a file, which will be either replayed as-is by
the JMT solver, or fitted automatically to a `Cox` by the other solvers.
Note that JMT requires that the last row of the trace must be a number,
<span>*not*</span> an empty row.

<table>
<caption>Solver support for statistical distributions</caption>
<tbody>
<tr class="odd">
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: center;"><p><strong>Distribution</strong></p></td>
<td style="text-align: center;"><code>CTMC</code></td>
<td style="text-align: center;"><code>FLUID</code></td>
<td style="text-align: center;"><code>JMT</code></td>
<td style="text-align: center;"><code>MAM</code></td>
<td style="text-align: center;"><code>MVA</code></td>
<td style="text-align: center;"><code>NC</code></td>
<td style="text-align: center;"><code>SSA</code></td>
</tr>
<tr class="odd">
<td style="text-align: center;">Cox2</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">Exp</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">Erlang</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">HyperExp</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="odd">
<td style="text-align: center;">Disabled</td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
</tr>
<tr class="even">
<td style="text-align: center;">Det</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="odd">
<td style="text-align: center;">Gamma</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: center;">Pareto</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="odd">
<td style="text-align: center;">Replayer</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
<tr class="even">
<td style="text-align: center;">Uniform</td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"><span class="math inline">✓</span></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
<td style="text-align: center;"></td>
</tr>
</tbody>
</table>

<span id="TAB_stat_distributions" label="TAB_stat_distributions">\[TAB\_stat\_distributions\]</span>

### Solver options

Solver options are encoded in <span class="smallcaps">Line</span> in a
structure array that is internally passed to the solution algorithms.
This can be specified as an argument to the constructor of the solver.
For example, the following two constructor invocations are identical

    s = SolverJMT(model)
    opt = SolverJMT.defaultOptions; s = SolverJMT(model, opt)

Modifiers to the default options can either be specified directly in the
`options` data structure, or alternatively be specified as argument
pairs to the constructor, i.e., the following two invocations are
equivalent

    s = SolverJMT(model,'method','exact')
    opt = SolverJMT.defaultOptions; opt.method='exact'; s = SolverJMT(model, opt)

Available solver options are as follows:

  - `cutoff` (`integer` >= 1) requires to ignore states where
    stations have more than the specified number of jobs. This is a
    mandatory option to analyze open classes using the CTMC solver.

  - `force` (`logical`) requires the solver to proceed with analyzing
    the model. This bypasses checks and therefore can result in the
    solver either failing or requiring an excessive amount of resources
    from the system.

  - `iter_max` (`integer` >= 1) controls the maximum number of
    iterations that a solver can use, where applicable. If `iter_max=
    `n, this option forces the `FLUID` solver to compute the ODEs
    over the timespan tn[0,10n/mu^{\min}], where mu^{\min}
    is the slowest service rate in the model. For the `MVA` solver this
    option instead regulates the number of successive substitutions
    allowed in the fixed-point iteration.

  - `iter_tol` (`double`) controls the numerical tolerance used to
    convergence of iterative methods. In the `FLUID` solver this option
    regulates both the absolute and relative tolerance of the ODE
    solver.

  - `init_sol` (`solver dependent`) re-initializes iterative solvers
    with the given configuration of the solution variables. In the case
    of `MVA`, this is a matrix where element (i,j) is the mean
    queue-length at station i in class j. In the case of
    `FLUID`, this is a model-dependent vector with the values of all the
    variables used within the ODE system that underpins the fluid
    approximation.

  - `keep` (`logical`) determines if the model-to-model transformations
    store on file their intermediate outputs. In particular, if
    `verbose`>= 1 then the location of the `.jsimg` models sent to
    JMT will be printed on screen.

  - `method` (`string`) configures the internal algorithm used to solve
    the model.

  - `samples` (`integer` >= 1) controls the number of samples
    collected <span>*for each*</span> performance index by
    simulation-based solvers. `JMT` requires a minimum number of samples
    of 5dot 10^3 samples.

  - `seed` (`integer` >= 1) controls the seed used by the
    pseudo-random number generators. For example, simulation-based
    solvers will give identical results across invocations only if
    called with the same `seed`.

  - `stiff` (`logical`) requires the solver to use a stiff ODE solver.

  - `timestamp` (`real interval`) requires the transient solver to
    produce a solution in the specified temporal range. If the value is
    set to [Inf,Inf] the solver will only return a
    steady-state solution. In the case of the `FLUID` solver and in
    simulation, [Inf,Inf] has the same
    computational cost of [exttt{0},Inf] therefore the
    latter is used as default.

  - `verbose` controls the verbosity level of the solver. Supported
    levels are 0 for silent, 1 for standard verbosity, 2 for debugging.

## Solver maintenance

The following best practices can be helpful in maintaining the
<span class="smallcaps">Line</span> installation:

  - To install a new release of JMT, it is necessary to delete the
    `JMT.jar` file under thr `’SolverJMT’` folder. This forces
    <span class="smallcaps">Line</span> to download the latest version
    of the JMT executable.

  - Periodically running the `jmtCleanTempDir` script can help removing
    temporary by-products of the JMT solver. This is strongly encouraged
    under repeated enabling of the `’keep’` option, as this stores on
    disk the temporary models sent to JMT.
