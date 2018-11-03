## Table of Contents 
[**Analysis methods**](https://github.com/line-solver/line/wiki/Network-models#analysis-methods)
- [Steady-state analysis](https://github.com/line-solver/line/wiki/Network-models#steady-state-analysis)
  - [Station average performance](https://github.com/line-solver/line/wiki/Network-models#station-average-performance)
  - [Station response time distribution](https://github.com/line-solver/line/wiki/Network-models#station-response-time-distribution)
  - [System average performance](https://github.com/line-solver/line/wiki/Network-models#system-average-performance)
- [Specifying states](https://github.com/line-solver/line/wiki/Network-models#specifying-states)
  - [Station states](https://github.com/line-solver/line/wiki/Network-models#station-states)
  - [Network states](https://github.com/line-solver/line/wiki/Network-models#network-states)
  - [Initialization of transient classes](https://github.com/line-solver/line/wiki/Network-models#initialization-of-transient-classes)
- [Transient analysis](https://github.com/line-solver/line/wiki/Network-models#transient-analysis)
  - [Computing transient averages](https://github.com/line-solver/line/wiki/Network-models#computing-transient-averages)
  - [First passage times into stations](https://github.com/line-solver/line/wiki/Network-models#first-passage-times-into-stations)
- [Sensitivity analysis and numerical optimization](https://github.com/line-solver/line/wiki/Network-models#sensitivity-analysis-and-numerical-optimization)
  - [Internal representation of the model structure](https://github.com/line-solver/line/wiki/Network-models#internal-representation-of-the-model-structure)
  - [Fast parameter update](https://github.com/line-solver/line/wiki/Network-models#fast-parameter-update)
  - [Refreshing a network topology with non-probabilistic routing](https://github.com/line-solver/line/wiki/Network-models#refreshing-a-network-topology-with-non-probabilistic-routing)
  - [Saving a network object before a change](https://github.com/line-solver/line/wiki/Network-models#saving-a-network-object-before-a-change)

# Analysis methods

## Steady-state analysis

### Station average performance

<span class="smallcaps">Line</span> decouples network specification from
its solution, allowing to evaluate the same model with multiple solvers.
Model analysis is carried out in <span class="smallcaps">Line</span>
according to the following general steps:

  - Step 1: Definition of the model.  
    This proceeds as explained in the previous chapters.

  - Step 2: Instantiation of the solver(s).  
    A solver is an instance of the `Solver` class.
    <span class="smallcaps">Line</span> offers multiple solvers, which
    can be configured through a set of common and individual solver
    options. For example,
    
        solver = SolverJMT(model);
    
    returns a handle to a simulation-based solver based on JMT,
    configured with default options.

  - Step 3: Solution.  
    Finally, this step solves the network and retrieves the concrete
    values for the performance indexes of interest. This may be done as
    follows, e.g.,
    
        % QN(i,r): mean queue-length of class r at station i
        QN = solver.getAvgQLen()
        % UN(i,r): utilization of class r at station i
        UN = solver.getAvgUtil()
        % RN(i,r): mean response time of class r at station i (summed on visits)
        RN = solver.getAvgRespT()
        % TN(i,r): mean throughput of class r at station i
        TN = solver.getAvgTput()
    
    Alternatively, all the above metrics may be obtained in a single
    method call as
    
        [QN,UN,RN,TN] = solver.getAvg()

In the methods above, <span class="smallcaps">Line</span> assigns
station and class indexes (e.g., i, r) in order of creation in
order of creation of the corresponding station and class objects.
However, large models may be easier to debug by checking results using
class and station names, as opposed to indexes. This can be done either
by requesting <span class="smallcaps">Line</span> to build a table with
the result

    AvgTable = solver.getAvgTable()

which however tends to be a rather slow data structure to use in case of
repeated invocations of the solver, or by indexing the matrices returned
by `getAvg` using the model objects. That is, if the first instantiated
node is `queue` with name `’MyQueue’` and the second instantiated class
is `cclass` with name `’MyClass’`, then the following commands are
equivalent

    QN(1,2)
    QN(queue,cclass)
    QN(model.getStationIndex('MyQueue'),model.getClassIndex('MyClass'))

Similar methods are defined to obtain aggregate performance metrics at
chain level at each station, namely `getAvgQLenChain` for queue-lengths,
`getAvgUtilChain` for utilizations, `getAvgRespTChain` for response
times, `getAvgTputChain` for throughputs, and the `getAvgChain` method
to obtain all the previous metrics.

### Station response time distribution

`SolverFluid` supports the computation of response time distributions
for individual classes through the `getCdfRespT` function. The function
returns the response time distribution for every station and class. For
example, the following code plots the cumulative distribution function
at steady-state for class 1 jobs when they visit station 2:

    solver = SolverFluid(model);
    FC = solver.getCdfRespT();
    plot(FC{2,1}(:,2),FC{2,1}(:,1)); xlabel('t'); ylabel('Pr(RespT<t)');

### System average performance

<span class="smallcaps">Line</span> also allows users to analyze models
for end-to-end performance indexes such a system throughput or system
response time. However, in models with class switching the notion of
system-wide metrics can be ambiguous. For example, consider a job that
enters the network in one class and departs the network in another
class. In this situation one may attribute system response time to
either the arriving class or the departing one, or attempt to partition
it proportionally to the time spent by the job within each class. In
general, the right semantics depends on the aim of the study.

LINE tackles this issue by supporting only the computation of system
performance indexes <span>*by chain*</span>, instead than by class. In
this way, since a job switching from a class to another remains by
definition in the same chain, there is no ambiguity in attributing the
system metrics to the chain. The solver functions `getAvgSys` and
`getAvgSysTable` return system response time and system throughput per
chain as observed: (i) upon arrival to the sink, for open classes; (ii)
upon arrival to the reference station, for closed classes.

In some cases, it is possible that a chain visits multiple times the
reference station before the job completes. This also affects the
definition of the system averages, since in some applications one may
want to avoid counting each visit as a completion of the visit to the
system. In such cases, <span class="smallcaps">Line</span> allows to
specify which classes of the chain can complete at the reference
station. For example, in the code below we require that a job visits
reference station 1 twice, in classes 1 and 2, but completes at the
reference station only when arriving in class 2. Therefore, the system
response time will be counted between successive passages in class 2.

    class1 = ClosedClass(model, 'ClosedClass1', 1, queue, 0);
    class2 = ClosedClass(model, 'ClosedClass2', 0, queue, 0);
    
    class1.completes = false;
    
    P = cell(2); % 2-classes model
    P{1,1} = [0,1; 0,0]; % routing within class 1 (no switching)
    P{1,2} = [0,0; 1,0]; % routing from class 1 into class 2
    P{2,1} = [0,0; 1,0]; % routing within class 2 (no switching)
    P{2,2} = [0,1; 0,0]; % routing from class 2 into class 2
    
    model.link(P);

Note that <span class="smallcaps">Line</span> does not allow a chain to
complete at heterogeneous stations, therefore the `completes` property
of a class always refers to the reference station for the chain.

## Specifying states

In some analyses it is important to specify the state of the network,
for example to assign the initial position of the jobs in a transient
analysis. We thus discuss the native support in
<span class="smallcaps">Line</span> for state modeling.

### Station states

We begin by explaining how to specify a state s_0. State modelling
is supported only for stations with scheduling policies that depend on
the number of jobs running or waiting at the node. For example, it is
not supported for shortest job first (`SchedStrategy.SJF`) scheduling,
in which state depends on the service time samples for the jobs.

Suppose that the network has R classes and that service
distributions are phase-type, i.e., that they inherit from `PhaseType`.
Let K_{r} be the number of phases for the service distribution in
class r at a given station. Then, we define three types of state
variables:

  - c_j: class of the job waiting in position j>= b of the
    buffer, out of the b currently occupied positions. If b=0,
    then the state vector is indicated with a single empty element
    c_1=0.

  - n_r: total number of jobs of class r in the station

  - b_r: total number of jobs of class r in the station’s buffer

  - s_{rk}: total number of jobs of class r running in phase
    k in the server

Here, by phase we mean the number of states of a distribution of class
`PhaseType`. If the distribution is not Markovian, then there is a
single phase. With these definitions, the table below illustrates how to
specify in <span class="smallcaps">Line</span> a valid state for a
station depending on its scheduling strategy. All state variables are
non-negative integers. The `SchedStrategy.EXT` policy is used for the
`Source` node, which may be seen as a special station with an infinite
pool of jobs sitting in the buffer and a dedicated server for each class
r=1,...,R.

| **Sched. strategy**       | **Station state vector**                                          | **State condition**                |
| :------------------------ | :---------------------------------------------------------------- | :--------------------------------- |
| `EXT`                     | [Inf,s_{11},...,s_{1K_1},...,s_{R1},...,s_{RK_R}]    | sum_k s_{rk}=1, forall r |
| `FCFS`, `HOL`, `LCFS`     | [c_{b},...,c_{1},s_{11},...,s_{1K_1},...,s_{R1},...,s_{RK_R}] | sum_{r}sum_{k} s_{rk}=1      |
| `SEPT`, `RAND`            | [b_{1},...,b_{R},s_{11},...,s_{1K_1},...,s_{R1},...,s_{RK_R}] | sum_{r}sum_{k} s_{rk}=1      |
| `PS`, `DPS`, `GPS`, `INF` | [s_{11},...,s_{1K_1},...,s_{R1},...,s_{RK_R}]                 | None                               |

State descriptors for Markovian scheduling
policies

<span id="TAB_state_policies" label="TAB_state_policies">\[TAB\_state\_policies\]</span>

States can be manually specified or enumerated automatically.
<span class="smallcaps">Line</span> library functions for handling and
generating states are as follows:

  - `State.fromMarginal`: enumerates all states that have the same
    marginal state [n_{1},n_{2},...,n_{R}].

  - `State.fromMarginalAndRunning`: restricts the output of
    `State.fromMarginal` to states with given number of running jobs,
    irrespectively of the service phase in which they currently run.

  - `State.fromMarginalAndStarted`: restricts the output of
    `State.fromMarginal` to states with given number of running jobs,
    all assumed to be in service phase k=1.

  - `State.fromMarginalBounds`: similar to `State.fromMarginal`, but
    produces valid states between given minimum and maximum of resident
    jobs.

  - `State.toMarginal`: extracts statistics from a state, such as the
    total number of jobs in a given class that are running at the
    station in a certain phase.

Note that if a function call returns an empty state (`[]`), this should
be interpreted as an indication that no valid state exists that meets
the required criteria. Often, this is because the state supplied in
input is invalid.

#### Example

We consider the example network in `example_closedModel_4.m`. We look at
the state of station 3, which is a multi-server FCFS station. There are
4 classes all having exponential service times except class 2 that has
Erlang-2 service times. We are interested to states with 2 running jobs
in class 1 and 1 in class 2, and with 2 jobs, respectively of classes 3
and 4, waiting in the buffer. We can automatically generate this state
space, which we store in the `space` variable, as:

    >> example_closedModel_4;
    >> space = State.fromMarginalAndRunning(model,3,[2,1,1,1],[2,1,0,0])
    space =
         4     3     2     1     0     0     0
         4     3     2     0     1     0     0
         3     4     2     1     0     0     0
         3     4     2     0     1     0     0

Here, each row of `space` corresponds to a valid state. The argument
`[2,1,1,1]` gives the number of jobs in the node for the 4 classes,
while `[2,1,0,0]` gives the number of running jobs in each class. This
station has four valid states, differing on whether the class-2 job runs
in the first or in the second phase of the Erlang-2 and on the relative
position of the jobs of class 3 and 4 in the waiting buffer.

To obtain states where the jobs have just started running, we can
instead use

    >> space = State.fromMarginalAndStarted(model,3,[2,1,1,1],[2,1,0,0])
    space =
         4     3     2     1     0     0     0
         3     4     2     1     0     0     0

If we instead remove the specification of the running jobs, we can use
`State.fromMarginal` to generate all possible combinations of states
depending on the class and phase of the running jobs. In the example,
this returns a space of 20 possible states.

    >> space = State.fromMarginal(model,3,[2,1,1,1],[2,1,0,0])
    space =
         4     3     2     1     0     0     0
         4     3     2     0     1     0     0
         4     2     2     0     0     1     0
         4     1     1     1     0     1     0
         4     1     1     0     1     1     0
         3     4     2     1     0     0     0
         3     4     2     0     1     0     0
         3     2     2     0     0     0     1
         3     1     1     1     0     0     1
         3     1     1     0     1     0     1
         2     4     2     0     0     1     0
         2     3     2     0     0     0     1
         2     1     1     0     0     1     1
         1     4     1     1     0     1     0
         1     4     1     0     1     1     0
         1     3     1     1     0     0     1
         1     3     1     0     1     0     1
         1     2     1     0     0     1     1
         1     1     0     1     0     1     1
         1     1     0     0     1     1     1

#### Assigning a state to a station

Given a single or multiple states, it is possible to assign the initial
state to a station using the `setState` function on that station’s
object. To cope with multiple states,
<span class="smallcaps">Line</span> offers the possibility to specify a
prior probability on the initial states, so that if multiple states have
a non-zero prior, then the solver will need to analyze the network from
all those states and weight the results according to the prior
probabilities. The default prior value assigned probability 1.0 to the
<span>*first*</span> specified state. The functions `setStatePrior` and
`getStatePrior` of the `Station` class can be used to check and change
the prior probabilities for the supplied initial states.

### Network states

A collection of states that are valid for each station is not
necessarily valid for the network as a whole. For example, if the sum of
jobs of a closed class exceeds the population of the class, then the
network state would be invalid. To identify these situations,
<span class="smallcaps">Line</span> requires to specify the initial
state of a network using functions supplied by the `Network` class.
These functions are `initFromMarginal`, `initFromMarginalAndRunning`,
and `initFromMarginalAndStarted`. They require a matrix with elements
`n`(i,r) specifying the total number of resident class-r jobs at
node i and the latter two require a matrix `s`(i,r) with the
number of running (or started) class-r jobs at node i. The user
can also manually verify if the supplied network state is going to be
valid using `State.IsValid`.

It is also possible to request <span class="smallcaps">Line</span> to
automatically identify a valid initial state, which is done using the
`initDefault` function available in the `Network` class. This is going
to select a state where:

  - no jobs in open classes are present in the network;

  - jobs in closed classes all start at their reference stations;

  - the server of reference stations are occupied in order of class id,
    i.e., jobs in the firstly created class are assigned to the server
    in phase 1, then spare servers are allocated to the second class in
    phase 1, and so forth;

  - if the scheduling strategy requires it, jobs are ordered in the
    buffer by class, with the firstly created class at the head and the
    lastly created class at the tail of the buffer.

Lastly, the `initFromAvgQLen` is a wrapper for `initFromMarginal` to
initialize the system as close as possible to the average steady-state
distribution of the network. Since averages are typically not
integer-valued, this function rounds the average values to the nearest
integer and adjusts the result to ensure feasibility of the
initialization.

### Initialization of transient classes

Because of class-switching, it is possible that a class r with a
non-empty population at time t=0 becomes empty at some position time
t'>t without ever being visited again by any job. `LINE` allows one
to place jobs in transient classes and therefore it will not trigger an
error in the presence of this situation. If a user wishes to prohibit
the use of a class at a station, it is sufficient to specify that the
corresponding service process uses the `Disabled` distribution.

Certain solvers may incur problems in identifying that a class is
transient and in setting to zero its steady-state measures. For example,
the `JMT` solver uses an heuristic whereby a class is considered
transient if it has fewer events than jobs initially placed in the
corresponding chain the class belongs to. For such classes, `JMT` will
set the values of steady-state performance indexes to zero.

## Transient analysis

So far, we have seen how to compute steady-state average performance
indexes, which are given by \[E[n]=imimits_{to +nfty }E[n(t)]\]
where n(t) is an arbitrary performance index, e.g., the queue-length
of a given class at time t.

We now consider instead the computation of the quantity E[n(t)|s_0],
which is the <span>*transient average*</span> of the performance index,
conditional on a given initial system state s_0. Compared to
n(t), this quantity averages the system state at time t across
all possible evolutions of the system from state s_0 during the
t time units, weighted by their probability. In other words, we
observe all possible stochastic evolutions of the system from state
s_0 for t time units, recording the final values of n(t) in
each trajectory, and finally average the recorded values at time t
to obtain E[n(t)|s_0].

### Computing transient averages

At present, <span class="smallcaps">Line</span> supports only transient
computation of queue-lengths, throughputs and utilizations using the
`CTMC` and `FLUID` solvers. Transient response times are not currently
supported, as they do not always obey Little’s law.

The computation of transient metrics proceeds similarly to the
steady-state case. We first obtain the handles for transient averages:

    [Qt,Ut,Tt] = model.getTransientHandlers();

After solving the model, we will be able to retrieve <span>*both*</span>
steady-state and transient averages as follows

    [QNt,UNt,TNt] = solver{s}.getTransientAvg(Qt,Ut,Tt)
    plot(QNt{1,1}(:,2), QNt{1,1}(:,1))

The transient average queue-length at node i for class r is
stored within `QNt{i,r}`.

Note that the above code does not show how to specify a maximum time
t for the output time series. This can be done using the `timespan`
field of the options, as described later in the solvers chapter.

### First passage times into stations

When the model is in a transient, the average state seen upon arrival to
a station changes over time. That is, in a transient, successive visits
by a job may experience different response time distributions. The
function `getTransientCdfRespT`, implemented by `SolverJMT` offers the
possibility to obtain this distribution given the initial state
specified for the model. As time passes, this distribution will converge
to the steady-state one computed by solvers equipped with the function
`getCdfRespT`.

However, in some cases one prefers to replace the notion of response
time distribution in transient by the one of *first passage time*, i.e.,
the distribution of the time to complete the <span>*first visit*</span>
to the station under consideration. The function
`getTransientCdfFirstPassT` provides this distribution, assuming as
initial state the one specified for the model, e.g., using `setState` or
`initDefault`. This function is available only in `SolverFluid` and has
a similar syntax as `getCdfRespT`.

## Sensitivity analysis and numerical optimization

Frequently, performance and reliability analysis requires to change one
or more model parameters to see the sensitivity of the results or to
optimize some goal function. In order to do this efficiently, we discuss
the internal representation of the `Network` objects used within the
<span class="smallcaps">Line</span> solvers. By applying changes
directly to this internal representation it is possible to considerably
speed-up the sequential evaluation of several models.

### Internal representation of the model structure

For efficiency reasons, once a user requests to solve a `Network`,
<span class="smallcaps">Line</span> calls internally generates a static
representation of the network structure using the `refreshStruct`
function. This function returns a representation object that is then
passed on to the chosen solver to parameterize the analysis.

The representation used within <span class="smallcaps">Line</span> is
the `NetworkStruct` class, which describes an extended multiclass
queueing network with class-switching and Coxian service times. The
representation can be obtained as follows

    qn = model.getStruct()

The table below presents the properties of the `NetworkStruct`
class.

| **Field**                              | **Type**               | **Description**                                                                                                                                                   |
| :------------------------------------- | :--------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cap`(i)                           | `integer`              | Total capacity at station i                                                                                                                                   |
| `chains`(c,r)                      | `logical`              | `true` if class r is in chain c, or `false` otherwise                                                                                                     |
| `classcap`(i,r)                    | `integer`              | Maximum buffer capacity available to class r at station i                                                                                                 |
| `classname`\{r\}                   | `string`               | Name of class r                                                                                                                                               |
| `classprio`(r)                     | `integer`              | Priority of class r (0 = highest priority)                                                                                                                    |
| `csmask`(r,s)                      | `logical`              | true if class r can switch into class s at some node                                                                                                      |
| <span>`isstation`</span>(i)        | <span>`logical`</span> | true if node i is a station                                                                                                                                   |
| <span>`isstateful`</span>(i)       | <span>`logical`</span> | true if node i is a stateful node                                                                                                                             |
| `mu`\{i,r\}(k)                     | `double`               | Coxian service or arrival rate in phase k for class r at station i, with `mu`\{i,r\}=`NaN` if `Disabled` and `mu`\{i,r\}=10^7 if `Immediate`. |
| `nchains`                              | `integer`              | Number of chains in the network                                                                                                                                   |
| `nclasses`                             | `integer`              | Number of classes in the network                                                                                                                                  |
| `nclosedjobs`                          | `integer`              | Total number of jobs in closed classes                                                                                                                            |
| `njobs`(r)                         | `integer`              | Number of jobs in class r (`Inf` for open classes)                                                                                                            |
| `nnodes`                               | `integer`              | Number of nodes in the network                                                                                                                                    |
| `nservers`(i)                      | `integer`              | Number of servers at station i                                                                                                                                |
| `nstations`                            | `integer`              | Number of stations in the network                                                                                                                                 |
| `nstateful`                            | `integer`              | Number of stateful nodes in the network                                                                                                                           |
| `nodenames`\{i\}                   | `string`               | Name of node i                                                                                                                                                |
| `nodetypes`\{i\}                   | `string`               | Type of node i (e.g., `NodeType.Sink`)                                                                                                                        |
| `nvars`                                | `integer`              | Number of local state variables at stateful nodes                                                                                                                 |
| `phases`(i,r)                      | `integer`              | Number of phases for service process of class r at station i                                                                                              |
| `phi`\{i,r\}(k)                    | `double`               | Coxian completion probability in phase k for class r at station i                                                                                     |
| `rates`(i,r)                       | `double`               | Service rate of class r at station i (or arrival rate if i is a `Source`)                                                                             |
| `refstat`(r)                       | `integer`              | Index of reference station for class r                                                                                                                        |
| `rt`(idx_{ir},idx_{js})            | `double`               | Probability of routing from stateful node i to j, switching class from r to s where, e.g., idx_{ir}=(i-1)*exttt{nclasses}+r.                |
| `rtnodes`(idx_{ir},idx_{js})       | `double`               | Same as `rt`, but i and j are nodes, not necessarily stateful ones.                                                                                       |
| `rtfun`(exttt{st1},st2) | `matrix`               | State-dependent routing table given initial (`st1`) and final (`st2`) state cell arrays. Table entries defined as in `rt`.                                        |
| `schedparam`(i,r)                  | `double`               | Parameter for class r strategy at station i                                                                                                               |
| `sched`\{i\}                       | `cell`                 | Scheduling strategy at station i (e.g., `SchedStrategy.PS`)                                                                                                   |
| `schedid`(i)                       | `integer`              | Scheduling strategy id at station i (e.g., `SchedStrategy.ID_PS`)                                                                                             |
| `sync`\{s\}                        | `struct`               | Data structure specifying a synchronization s among nodes                                                                                                     |
| `scv`(i,r)                         | `double`               | Squared coefficient of variation of class r service times at station i (or inter-arrival times if station i is a `Source`)                            |
| `space`\{t\}                       | `integer`              | The t-th state in the state space (or a portion thereof). This field may be initially empty and updated by the solver during execution.                       |
| `state`\{i\}                       | `integer`              | Current state of stateful node i. This field may be initially empty and updated by the solver during execution.                                               |
| `visits`\{c\}(i,r)                 | `double`               | Number of visits that a job in chain c pays to node i in class r                                                                                      |
| `varsparam`\{i\}                   | `double`               | Parameters for local variable instantiation at stateful node i                                                                                                |

`NetworkStruct` properties

<span id="TAB_QN" label="TAB_QN">\[TAB\_QN\]</span>

### Fast parameter update

Successive invocations of `getStruct()` will return a cached copy of the
`NetworkStruct` representation, unless the user has called
`model.refreshStruct()` or `model.reset()` in-between the invocations.
The `refreshStruct` function regenerates the internal representation,
while `reset` destroys it, together with all other representations and
cached results stored in the `Network` object. In the case of `reset`,
the internal data structure will be regenerated at the next
`refreshStruct()` or `getStruct()` call.

The performance cost of updating the representation can be significant,
as some of the structure array field require a dedicated algorithm to
compute. For example, finding the chains in the model requires an
analysis of the weakly connected components of the network routing
matrix. For this reason, the `Network` class provides several functions
to selectively refresh only part of the `NetworkStruct` representation,
once the modification has been applied to the objects (e.g., stations,
classes, ...) used to define the network. These functions are as
follows:

  - `refreshArrival`: this function should be called after updating the
    inter-arrival distribution at a `Source`.

  - `refreshCapacity`: this function should be called after changing
    buffer capacities, as it updates the `capacity` and `classcapacity`
    fields.

  - `refreshChains`: this function should be used after changing the
    routing topology, as it refreshes the `rt`, `chains`, `nchains`,
    `nchainjobs`, and `visits` fields.

  - `refreshPriorities`: this function updates class priorities in the
    `classprio` field.

  - `refreshScheduling`: updates the `sched`, `schedid`, and
    `schedparam` fields.

  - `refreshService`: updates the `mu`, `phi`, `phases`, `rates` and
    `scv` fields.

For example, suppose we wish to update the service time distribution for
class-1 at node 1 to be exponential with unit rate. This can be done
efficiently as follows:

    queue.setService(class1, Exp(1.0));
    model.refreshService;

### Refreshing a network topology with non-probabilistic routing

The `resetNetwork` function should be used before changing a network
topology with non-probabilistic routing. It will destroy by default all
class switching nodes. This can be avoided if the function is called as,
e.g., `model.resetNetwork(false)`. The default behavior is though shown
in the next example

    >> model = Network('model');
    node{1} = ClassSwitch(model,'CSNode',[0,1;0,1]);
    node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
    >> model.getNodes
    ans =
      2x1 cell array
        {1x1 ClassSwitch}
        {1x1 Queue}
    >> model.resetNetwork
    ans =
      1x1 cell array
        {1x1 Queue}

As shown, `resetNetwork` updates the station indexes and the revised
list of nodes that compose the topology is obtained as a return
parameter. To avoid stations to change index, one may simply create
`ClassSwitch` nodes as last before solving the model. This node list can
be employed as usual to reinstantiate new stations or `ClassSwitch`
nodes. The `addLink`, `setRouting`, and possibly the `setProbRouting`
functions will also need to be re-applied as described in the previous
sections.

### Saving a network object before a change

The `Network` object, and its inner objects that describe the network
elements, are always passed by reference. The `copy` function should be
used to clone <span class="smallcaps">Line</span> objects, for example
before modifying a parameter for a sensitivity analysis. This function
recursively clones all objects in the model, therefore creating an
independent copy of the network. For example, consider the following
code

    modelByRef = model; modelByRef.setName('myModel1');
    modelByCopy = model.copy; modelByCopy.setName('myModel2');

Using the `getName` function it is then possible to verify that `model`
has now name `’myModel1’`, since the first assignment was by reference.
Conversely, `modelByCopy.setName` did not affect the original `model`
since this is a clone of the original network.
