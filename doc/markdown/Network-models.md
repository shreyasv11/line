## Table of Contents 
[**Network models**](https://github.com/line-solver/line/wiki/Network-models#network-models)
- [Network object definition](https://github.com/line-solver/line/wiki/Network-models#network-object-definition)
  - [Creating a network and its nodes](https://github.com/line-solver/line/wiki/Network-models#creating-a-network-and-its-nodes)
  - [Job classes](https://github.com/line-solver/line/wiki/Network-models#job-classes)
  - [Routing strategies](https://github.com/line-solver/line/wiki/Network-models#routing-strategies)
  - [Class switching](https://github.com/line-solver/line/wiki/Network-models#class-switching)
  - [Finite buffers](https://github.com/line-solver/line/wiki/Network-models#finite-buffers)
  - [Service and inter-arrival time processes](https://github.com/line-solver/line/wiki/Network-models#service-and-inter-arrival-time-processes)
  - [Debugging and visualization](https://github.com/line-solver/line/wiki/Network-models#debugging-and-visualization)
- [Model import and export](https://github.com/line-solver/line/wiki/Network-models#model-import-and-export)
  - [Creating a <span class="smallcaps">Line</span> model using JMT](https://github.com/line-solver/line/wiki/Network-models#creating-a-line-model-using-jmt)

# Network models

Throughout this chapter, we discuss the specification of `Network`
models. It is important to keep in mind that not all of the model
features described in the present chapter are supported by every
<span class="smallcaps">Line</span> solver. However, upon calling a
solver, <span class="smallcaps">Line</span> will automatically detect if
the supplied model can be analyzed by that solver and return an empty
set if not. Tables are given later in the manual summarizing the
features supported by each solver.

## Network object definition

### Creating a network and its nodes

A queueing network can be described in
<span class="smallcaps">Line</span> using the `Network` class
constructor with a unique string identifying the model name:

    model = Network('myModel');

The returned object of the `Network` class offers functions to
instantiate and manage resource *nodes* (stations, delays, caches, ...)
visited by jobs of several types (*classes*).

A <span>node</span> is a resource in the network that can be visited by
a job. A node must have a unique name and can either be
<span>*stateful*</span> or <span>*stateless*</span>, the latter meaning
that the node does not require state variables to determine the actions
it performs on the system. If jobs visiting a stateful node can be
required to spend time in it, the node is also said to be a
<span>*station*</span>. A list of nodes available in `Network` models is
given in the next
table.

| <span>Node</span> | <span>Type</span> | <span>Description</span>                                      |
| :---------------- | :---------------- | :------------------------------------------------------------ |
| `Cache`           | stateful node     | A class-switching router based on cache hits/misses           |
| `ClassSwitch`     | stateless node    | A class-switching router based on a static probability matrix |
| `Delay`           | station           | A station where jobs spend time without queueing              |
| `Queue`           | station           | A generic queueing element                                    |
| `Sink`            | stateless node    | Exit point for jobs in open classes                           |
| `Source`          | station           | Entry point for jobs in open classes                          |

Nodes available in `Network` models.

For example, a sink is a stateless node, since its behaviour does not
require state variables and jobs cannot sojourn in it. Instead, a
first-come first-served queue is a station, since jobs can sojourn
inside its buffer and servers. A source is also treated in
<span class="smallcaps">Line</span> as a station since the inter-arrival
time of jobs from the external world is considered as a time spent in
the source, although this is not counted as part of the system response
time. Lastly, a cache is a stateful node, since it needs to keep track
of the cached items, however it is not a station since passage through
this node occurs instantaneously.

We now provide more details on each of the nodes available in `Network`
models.

##### Queue node.

Among the listed nodes, the most important one is the `Queue`, which
specifies a queueing station from its name and scheduling strategy, e.g.

    queue = Queue(model, 'Queue1', SchedStrategy.FCFS);

It is also possible to instantiate a queue using the `QueueingStation`
constructor, which is merely an alias for the `Queue` class.

Valid scheduling strategies are specified within the `SchedStrategy`
static class and include:

  - First-come first-served (`SchedStrategy.FCFS`)

  - Infinite-server (`SchedStrategy.INF`)

  - Processor-sharing (`SchedStrategy.PS`)

  - Discriminatory processor-sharing (`SchedStrategy.DPS`)

  - Generalized processor-sharing (`SchedStrategy.GPS`)

  - Shortest expected processing time (`SchedStrategy.SEPT`)

  - Shortest job first (`SchedStrategy.SJF`)

  - Head-of-line priority (`SchedStrategy.HOL`)

If a strategy requires class weights, these can be specified directly as
an argument to the `setService` function or using the `setStrategyParam`
function, see later the description of DPS scheduling for an example.

##### Delay node.

Infinite-server stations may be instantiated either as objects of
`Queue` class with the `SchedStrategy.INF` strategy or using the
following specialized constructor

    delay = Delay(model, 'ThinkTime');

As for queues, for readability it is possible to instantiate delay nodes
using the `DelayStation` constructor, which is entirely equivalent to
the one of the `Delay` class.

##### Source and Sink nodes.

As seen in the M/M/1 getting started example, these nodes are mandatory
elements for the specification of open classes. Their constructor only
requires a specification of the unique name associated to the nodes:

    source = Source(model, 'Source');
    sink = Sink(model, 'Sink');

##### ClassSwitch node.

This is a stateless node to change the class of a transiting job based
on a static probabilistic policy. For example, it is possible to specify
that all jobs belonging to class 1 should become of class 2, or that a
class 2 job should become of class 1 with probability 0.3. This
example is instantiated as follows

    cs = ClassSwitch(model, 'ClassSwitchPoint',[0.0, 1.0; 0.3, 0.7]);

##### Cache node.

This is a stateful node to store one or more items in a cache of finite
size, for which it is possible to specify a replacement policy. The
cache constructor requires the total cache capacity and the number of
items that can be referenced by the jobs in transit,
    e.g.,

    cacheNode = Cache(model, 'Cache1', nitems, capacity, ReplacementPolicy.LRU);

If the capacity is an integer (e.g., `[15]`) , then it represents the
total number of items that can be cached and the value cannot be greater
than the number of items. Conversely, if it is a vector (e.g., `[10,5]`)
then the node is a list-based cache, where the vector entries specify
the capacity of each list. We point to \[[Gast et al. 2014](https://dl.acm.org/citation.cfm?id=2745850)\] for more details on
list-based caches and their replacement policies.

Available replacement policies are specified within the
`ReplacementPolicy` static class and include:

  - First-in first-out (`ReplacementPolicy.FIFO`)

  - Random replacement (`ReplacementPolicy.RAND`)

  - Least-recently used (`ReplacementPolicy.LRU`)

  - Strict first-in first-out (`ReplacementPolicy.SFIFO`)

Upon cache hit or cache miss, a job in transit is switched to a
user-specified class. More details are given later in
Section [1.1.4](#class-switching).

### Job classes

Jobs travel within the network placing service demands at the stations.
The demand placed by a job at a station depends on the class of the job.
Jobs in <span>*open classes*</span> arrive from the external world and,
upon completing the visit, leave the network. Jobs in <span>*closed
classes*</span> start within the network and are forbidden to ever leave
it, perpetually cycling among the nodes.

#### Open classes

The constructor for an open class only requires the class name and the
creation of special nodes called `Source` and `Sink`

    source = Source(model, 'Source');
    sink = Sink(model, 'Sink');

Sources are special stations holding an infinite pool of jobs and
representing the external world. Sinks are nodes that route a departing
job back into this infinite pool, i.e., into the source. Note that a
network can include at most a single `Source` and a single `Sink`.

Once source and sink are instantiated in the model, it is possible to
instantiate open classes using

    class1 = OpenClass(model, 'Class1');

<span class="smallcaps">Line</span> does not require to associate source
and sink with the open classes in their constructors, as this is done
automatically. However, the <span class="smallcaps">Line</span> language
requires to explicitly create these nodes since the routing topology
needs to indicate the arrival and departure points of jobs in open
classes. However, if the network does not includes open classes, the
user will not need to instantiate a `Source` and a `Sink`.

#### Closed classes

To create a closed class, we need instead to indicate the number of jobs
that start in that class (e.g., 5 jobs) and the <span>*reference
station*</span> for that class (e.g., `queue`), i.e.:

    class2 = ClosedClass(model, 'Class2', 5, queue);

The reference station indicates a point in the network used to calculate
certain performance indexes, called <span>*system performance
indexes*</span>. The end-to-end response time for a job in an open class
to traverse the system is an example of system performance index (system
response time). The reference station of an open class is always
automatically set by <span class="smallcaps">Line</span> to be the
`Source`. Conversely the reference station needs to be indicated
explicitly in the constructor for closed classes, since the point at
which a class job completes execution depends on the semantics of the
model.

#### Mixed models

<span class="smallcaps">Line</span> also accepts models where a user has
instantiated both open and closed classes. The only requirement is that,
if two classes communicate by means of a class-switching mechanism, then
the two classes must either be all closed or all open. In other words,
classes in the same chain must either be both closed or both open.
Furthermore, for closed classes in the same chain it is required that
the reference station is the same.

#### Class priorities

If a class has a priority, with 0 representing the highest priority,
this can be specified as an additional argument to both `OpenClass` and
`ClosedClass`, e.g.,

    class2 = ClosedClass(model, 'Class2', 5, queue, 0);

In `Network` models, priorities are intended as hard priorities and the
only supported priority scheduling strategy (`SchedStrategy.HOL`) is
non-preemptive. Weight-based policies such as DPS and GPS may be used,
as an alternative, to prevent starvation of jobs in low priority
classes.

### Routing strategies

#### Probabilistic routing

Jobs travel between nodes according to the network topology and a
routing strategy. Typically a queueing network will use a probabilistic
routing strategy (`RoutingStrategy.PROB`), which requires to specify
routing probabilities among the nodes. The simplest way to specify a
large routing topology is to define the routing probability matrix for
each class, followed by a call to the `link` function. This function
will automatically add certain nodes to the network to ensure the
correct switching of class for jobs moving between stations
(`ClassSwitch` elements).

In the running case, we may instantiate a routing topology as follows:

    P = cellzeros(2,4);
    P{class1}(source,queue) = 1.0;
    P{class1}(queue,[queue,delay]) = [0.3,0.7]; % self-loop with probability 0.3
    P{class1}(delay,sink) = 1.0;
    P{class2}(delay,queue) = 1.0; % closed class starts at delay
    P{class2}(queue,delay) = 1.0;
    model.link(P);

When used as arguments to a cell array or matrix, class and node objects
will be replaced by a corresponding numerical index. Normally, the
indexing of classes and nodes matches the order in which they are
instantiated in the model and one can therefore specify the routing
matrices using this property. In this case we would have

    P = cellzeros(2,4);
    P{class1} = [0,1,0,0;   % row: source
                 0,.3,.7,0; % row: queue
                 0,0,0,1;   % row: delay
                 0,0,0,0];  % row: sink
    P{class2} = [0,0,0,0;
                 0,0,1,0;
                 0,1,0,0;
                 0,0,0,0];
    model.link(P);

The `getClassIndex` and `getNodeIndex` functions return the numerical
index associated to a node name, e.g., `model.getNodeIndex(’Delay’)`.
Class and node names in a network need to be unique. The list of used
names can be obtained with the `getClassNames`, `getStationNames`, and
`getNodeNames` functions of the `Network` class.

It is also important to note that the routing matrix in the last example
is specified between <span>*nodes*</span>, instead than between just
stations or stateful nodes, which means that elements such as the `Sink`
need to be explicitly considered in the routing matrix. The only
exception is that `ClassSwitch` elements do not need to be explicitly
instantiated and explicited in the routing matrix, provided that one
uses the `link` function to instantiate the topology. Note that the
routing matrix assigned to a model can be printed on screen in
human-readable format using the `printRoutingMatrix` function.

#### Other routing strategies

The above routing specification style is only for models with
probabilistic routing strategies between every pair of nodes. A
different style should be used for scheduling policies that do not
require to explicit routing probabilities, as in the case of
state-dependent routing. Currently supported strategies include:

  - Round robin (`RoutingStrategy.RR`). This is a non-probabilistic
    strategy that sends jobs to outgoing links in a cyclic order.

  - Random routing (`RoutingStrategy.RAND`). This is equivalent to a
    standard probabilistic strategy that for each class assigns
    identical values to the routing probabilities of all outgoing links.

  - Join-the-Shortest-Queue (`RoutingStrategy.JSQ`). This is a
    non-probabilistic strategy that sends jobs to the destination with
    the smallest total number of jobs in it. If multiple stations have
    the same total number of jobs, then the destination is chosen at
    random with equal probability across these stations.

For such policies, the function `addLink` should be first used to
specify pairs of connected nodes

    model.addLink(queue, queue); %self-loop
    model.addLink(queue, delay);

Then an appropriate routing strategy should be selected at every node,
e.g.,

    queue.setRouting(class1,RoutingStrategy.RR);

assigns round robin among all outgoing links from the `queue` node.

A model could also include both classes with probabilistic routing
strategies and classes that use round robin or other non-probabilistic
startegies. To instantiate routing probabilities in such situations one
should then use, e.g.,

    queue.setRouting(class1,RoutingStrategy.PROB);
    queue.setProbRouting(class1, queue, 0.7)
    queue.setProbRouting(class1, delay, 0.3)

where `setProbRouting` assigns the routing probabilities to the two
links.

### Class switching

In <span class="smallcaps">Line</span>, jobs can switch class while they
travel between nodes (including self-loops on the same node). For
example, this feature can be used to model queueing properties such as
re-entrant lines in which a job visiting a station a second time may
require a different average service demand than at its first visit.

A chain defines the set of reachable classes for a job that starts in
the given class r and over time changes class. Since class switching
in <span class="smallcaps">Line</span> does not allow a closed class to
become open, and vice-versa, chains can themselves be classified into
<span>*open chains*</span> and <span>*closed chains*</span>, depending
on the classes that compose them.

Jobs in open classes can only switch to another open class. Similarly,
jobs in closed classes can only switch to a closed class. Thus, class
switching from open to closed classes (or vice-versa) is forbidden. The
strategy to describe the class switching mechanism is integrated in the
specification of the routing between stations as described next.

#### Probabilistic class switching

In models with class switching and probabilistic routing at all nodes, a
routing matrix is required for each possible pair of source and target
classes. For example, suppose that in the previous example the job in
the closed class `class2` switches into a new closed class (`class3`)
while visiting the `queue` node. We can specify this routing strategy as
follows:

    class3 = ClosedClass(model, 'Class3', 0, queue, 0);
    
    P = cellzeros(3,3,4);
    P{class1,class1}(source, queue) = 1.0;
    P{class1,class1}(queue, [queue,delay]) = [0.3,0.7];
    P{class1,class1}(delay, sink) = 1.0;
    P{class2,class3}(delay, queue) = 1.0; % closed class starts at delay
    P{class3,class2}(queue, delay) = 1.0;
    model.link(P);

where `P{r,s}` is the routing matrix for jobs switching from class `r`
to `s`. That is, `P{r,s}(i,j)` is the probability that a job in class
`r` departs node `i` routing into node `j` as a job of class `s`.

Importantly, <span class="smallcaps">Line</span> assumes that a job
switches class an instant <span>*after*</span> leaving a station, thus
the performance metrics of a class at the node refer to the class that
jobs had upon arrival to that node.

Depending on the specified probabilities, a job will be able to switch
class only among a subset of the available classes. Each subset is
called a <span>*chain*</span>. Chains are computed in
<span class="smallcaps">Line</span> as the weakly connected components
of the routing probability matrix of the network, when this is seen as
an undirected graph. The function `model.getChains` produces the list of
chains for the model, inclusive of a list of their composing classes.

An advanced feature of <span class="smallcaps">Line</span> available for
example within the `Cache` node, is that the class-switching decision
can dynamically depend on the state of the node (e.g., cache hit/cache
miss). However, in order to statically determine chains,
<span class="smallcaps">Line</span> requires that every class-switching
node declares the pair of classes that can potentially communicate with
each other via a switch. This is called the <span>*class-switching
mask*</span> and it is automatically computed. The boolean matrix
returned by the `model.getClassSwitchingMask` function provides this
mask, which has entry in row r and column s set to true only if
jobs in class r can switch into class s at some node in the
network.

#### Class switching with non-probabilistic routing strategies

In the presence of non-probabilistic routing strategies, one needs to
specify more details of the class switching mechanism. This can be done
through addition to the network topology of `ClassSwitch` elements. The
constructor of this node requires to specify a probability matrix C
such that C(r,s) is the probability that a job of class r
arriving into the `ClassSwitch` switches to class s during the
visit. For example, in a 2-class model the following node will switch
all visiting jobs into class 2

    C = [0, 1; 0, 1];
    node = ClassSwitch(model, 'CSNode',C);

Note that for a network with M stations, up to M^2 `ClassSwitch`
elements may be required to implement class-switching across all
possible links, including self-loops. Moreover, refreshing network
parameters under non-probabilistic routing strategies may .

Contrary to the `link` function, one cannot specify in the argument to
`setProbRouting` a class switching probability. The `setProbRouting`
function should instead be used to route the job through an appropriate
`ClassSwitch` element.

#### Routing probabilities for Source and Sink nodes

In the presence of open classes, and in mixed models with both open and
closed classes, one needs only to specify the routing probabilities
<span>*out*</span> of the source. The probabilities out of the sink can
all be set to zero for all classes and destinations (including
self-loops). The solver will take care of adjusting these inputs to
create a valid routing table.

#### Cache-based class-switching

Upon cache hit or cache miss, a job in transit is switched to a
user-specified class, as specified by the `setHitClass` and
`setMissClass`, so that it can be routed to a different destination
based on wether it found the item in the cache or not. The `setRead`
function allows the user to specify a discrete distribution (e.g.,
`Zipf`, `DiscreteDistrib`) for the frequency at which an item is
requested. For example,

    refModel = Zipf(0.5,nitems);
    cacheNode.setRead(initClass, refModel);
    cacheNode.setHitClass(initClass, hitClass);
    cacheNode.setMissClass(initClass, missClass);

Here `initClass`, `hitClass`, and `missClass` can be either open or
closed instantiated as usual with the `OpenClass` or `ClosedClass`
constructors.

#### Reference station

Before we have shown that the specification of classes requires to
choose a reference station. In <span class="smallcaps">Line</span>,
reference stations are properties of chains, thus if two closed classes
belong to the same chain they must have the same reference station. This
avoids ambiguities in the definition of the completion point for jobs
within a chain.

For example, the system throughput for a chain is defined as sum of the
arrival rates at the reference station for all classes in that chain.
That is, the solver counts a return to the reference station as a
completion of the visit to the system. In the case of open chains, the
reference station is always the `Source` and the system throuhput
corresponds to the rate at which jobs arrive to the sink `Sink`, which
may be seen as the arrival rate seen by the infinite pool of jobs in the
external world. If there is no class switching, each chain contain a
single class, thus per-chain and per-class performance indexes will be
identical.

#### Tandem and cyclic topologies

Tandem networks are open queueing networks with a serial topology.
<span class="smallcaps">Line</span> provides functions that ease the
definition of tandem networks of stations with exponential service
times. For example, we can rapidly instantiate a tandem network
consisting of stations with PS and INF scheduling as follows

    A = [10,20]; % A(r) - arrival rate of class r
    D = [11,12; 21,22]; % D(i,r) - class-r demand at station i (PS)
    Z = [91,92; 93,94]; % Z(i,r)  - class-r demand at station i (INF)
    modelPsInf = Network.tandemPsInf(A,D,Z)

The above snippet instantiates an open network with two queueing
stations (PS), two delay stations (INF), and exponential distributions
with the given inter-arrival rates and mean service times. The
`Network.tandemPs`, `Network.tandemFcfs`, and `Network.tandemFcfsInf`
functions provide static constructors for networks with other
combinations of scheduling policies, namely only PS, only FCFS, or FCFS
and INF.

A tandem network with closed classes is instead called a cyclic network.
Similar to tandem networks, <span class="smallcaps">Line</span> offers a
set of static constructors: `Network.cyclicPs`, `Network.cyclicPsInf`,
`Network.cyclicFcfs`, and `Network.cyclicFcfsInf`. These functions only
require to replace the arrival rate vector `A` by a vector `N`
specifying the job populations for each of the closed classes, e.g.,

    N = [10,20]; % N(r) - closed population in class r
    D = [11,12; 21,22]; % D(i,r) - class-r demand at station i (PS)
    modelPsInf = Network.cyclicPs(N,D)

### Finite buffers

The functions `setCapacity` and `setChainCapacity` of the `Station`
class are used to place constraints on the number of jobs, total or for
each chain, that can reside within a station. Note that
<span class="smallcaps">Line</span> does not allow one to specify buffer
constraints at the level of individual classes, unless chains contain a
single class, in which case `setChainCapacity` is sufficient for the
purpose.

For example,

    example_closedModel_3
    delay.setChainCapacity([1,1])
    model.refreshCapacity()

creates an example model with two chains and three classes (specified in
`example_closedModel_3.m`) and requires the second station to accept a
maximum of one job in each chain. Note that if we were to ask for a
higher capacity, such as `setChainCapacity([1,7])`, which exceeds the
total job population in chain 2, <span class="smallcaps">Line</span>
would have automatically reduced the value 7 to the chain 2 job
population (2). This automatic correction ensures that functions that
analyze the state space of the model do not generate unreachable states.

The `refreshCapacity` function updates the buffer parameterizations,
performing appropriate sanity checks. Since `example_closedModel_3` has
already invoked a solver prior to our changes, the requested
modifications are materially applied by
<span class="smallcaps">Line</span> to the network only after calling an
appropriate `refreshStruct` function, see the sensitivity analysis
section. If the buffer capacity changes were made before the first
solver invocation on the model, then there would not be need for a
`refreshCapacity` call, since the internal representation of the
`Network` object used by the solvers is still to be created.

### Service and inter-arrival time processes

A number of statistical distributions are available to specify job
service times at the stations and inter-arrival times from the `Source`
station. The class `PhaseType` offers distributions that are
analytically tractable, which are defined upon certain absorbing Markov
chains consisting of one or more states (<span>*phases*</span>) that are
called phase-type distributions. They include as special case the
following distributions supported in
<span class="smallcaps">Line</span>, along with their respective
constructors:

  - Exponential distribution: `Exp`(lambda), where lambda is
    the rate of the exponential

  - n-phase Erlang distribution: `Erlang`(alpha, n), where
    alpha is the rate of each of the n exponential phases

  - 2-phase hyper-exponential distribution:
    `HyperExp`(p,lambda1,lambda2), that returns an exponential
    with rate lambda1 with probability p, and an exponential
    with rate lambda2 otherwise.

  - 2-phase Coxian distribution: `Cox2`(mu1,mu2,phi1),
    which assigns rates mu1 and mu2 to the two rates, and
    completion probability from phase 1 equal to phi1 (the
    probability from phase 2 is phi2=1.0).

For example, given mean mu=0.2 and squared coefficient of variation
SCV=10, where SCV=variance/mu^2, we can assign to a node a
2-phase Coxian service time distribution with these moments as

    queue.setService(class2, Cox2.fitMeanAndSCV(0.2,10));

Inter-arrival time distributions can be instantiated in a similar way,
using `setArrival` instead of `setService` on the `Source` node. For
example, if the `Source` is node 3 we may assign the inter-arrival times
of class 2 to be exponential with mean 0.1 as follows

    source.setArrival(class2, Exp.fitMeanAndSCV(0.1));

where we have used a single parameter in `fitMeanAndSCV` since the
exponential distribution does not allow to choose the SCV.

Non-Markovian distributions are also available, but typically they
restrict the available network analysis techniques to simulation. They
include the following distributions:

  - Deterministic distribution: `Det`(mu) assigns probability 1.0
    to the value mu.

  - Uniform distribution: `Uniform`(a,b) assigns uniform probability
    1/(b-a) to the interval [a,b].

  - Gamma distribution: `Gamma`(alpha, k) assigns a gamma density
    with shape alpha and scale k.

  - Pareto distribution: `Pareto`(alpha, k) assigns a Pareto
    density with shape alpha and scale k.

Lastly, we discuss two special distributions. The `Disabled`
distribution can be used to explicitly forbid a class to receive service
at a station. This may be useful in models with sparse routing matrices,
both to ensure an efficient model solution and to debug the model
specification. Performance metrics for disabled classes will be set to
`NaN`.

Conversely, the `Immediate` class can be used to specify instantaneous
service (zero service time). Typically,
<span class="smallcaps">Line</span> solvers will replace zero service
times with small positive values (arepsilon=10^{-7}).

#### Fitting a distribution

The `fitMeanAndSCV` function is available for all distributions that
inherit from the `PhaseType` class. This function provides exact or
approximate matching of the requested moments, depending on the
theoretical constraints imposed by the distribution. For example, an
Erlang distribution with SCV=0.75 does not exist, because in a
n-phase Erlang it must be SCV=1/n. In a case like this,
`Erlang.fitMeanAndSCV(1,0.75)` will return the closest approximation,
e.g., a 2-phase Erlang (SCV=0.5) with unit mean. The Erlang distribution
also offer a function `fitMeanAndOrder`(mu,n), which instantiates a
n-phase Erlang with given mean mu.

In distributions that are uniquely determined by more than two moments,
`fitMeanAndSCV` chooses a particular assignment of the residual degrees
of freedom other than mean and SCV. For example, `HyperExp` depends on
three parameters, therefore it is insufficient to specify mean and SCV
to identify the distribution. Thus, `HyperExp.fitMeanAndSCV`
automatically chooses to return a probability of selecting phase 1 equal
to 0.99, as this spends the degree of freedom corresponding to the
(unspecified) third moment of the distribution. Compared to other
choices, this particular assignment corresponds to an higher probability
mass in the tail of the distribution.

#### Inspecting and sampling a distribution

To verify that the fitted distribution has the expected mean and SCV it
is possible to use the `getMean` and `getSCV` functions, e.g.,

    >> dist = Exp(1);
    >> dist.getMean
    ans =
         1
    >> dist.getSCV
    ans =
         1

Moreover, the `sample` function can be used to generate values from the
obtained distribution, e.g. we can generate 3 samples as

    >> dist.sample(3)
    ans =
        0.2049
        0.0989
        2.0637

The `evalCDF` and `evalCDFInterval` functions return the cumulative
distribution function at the specified point or within a range, e.g.,

    >> dist.evalCDFInterval(2,5)
    ans =
        0.1286
    >> dist.evalCDF(5)-dist.evalCDF(2)
    ans =
        0.1286

For more advanced uses, the distributions of the `PhaseType` class also
offer the possibility to obtain the standard (D_0,D_1)
representation used in the theory of Markovian arrival processes by
means of the `getRenewalProcess` function. The result will be a cell
array where element k+1 corresponds to matrix D_k.

#### Temporal dependent processes

It is sometimes useful to specify the statistical properties of a
<span>*time series*</span> of service or inter-arrival times, as in the
case of systems with short- and long-range dependent workloads. When the
model is stochastic, we refer to these as situations where one specifies
a <span>*process*</span>, as opposed to only specifying the
<span>*distribution*</span> of the service or inter-arrival times. In
<span class="smallcaps">Line</span> processes inherit from the
`PointProcess` class, and include the 2-state Markov-modulated Poisson
process (`MMPP2`) and empirical traces read from files (`Replayer`).

In particular, <span class="smallcaps">Line</span> assumes that
empirical traces are supplied as text files (ASCII), formatted as a
column of numbers. Once specified, the `Replayer` object can be used as
any other distribution. This means that it is possible to run a
simulation of the model with the specified trace. However, analytical
solvers will require tractable distributions from the `PhaseType` class.

#### Scheduling parameters

Upon setting service distributions at a station, one may also specify
scheduling parameters such as weights as additional arguments to the
`setService` function. For example, if the node implements
discriminatory processor sharing (`SchedStrategy.DPS`), the command

    queue.setService(class2, Cox2.fitMeanAndSCV(0.2,10), 5.0);

assigns a weight 5.0 to jobs in class 2. The default weight of a class
is 1.0.

### Debugging and visualization

JSIMgraph is the graphical simulation environment of the JMT suite.
<span class="smallcaps">Line</span> can export models to this
environment for visualization purposes using the command

    model.jsimgView

An example is shown in Figure  below. Using a related function,
`jsimwView`, it is also possible to export the model to the JSIMwiz
environment, which offers a wizard-based interface.

![jsimgView
function<span label="jsimgView-function"></span>](./images/jsimgView.png)

Another way to debug a <span class="smallcaps">Line</span> model is to
transforming it into a MATLAB graph object, e.g.

    G = model.getGraph();
    plot(G,'EdgeLabel',G.Edges.Weight,'Layout','Layered')

plots a graph of the network topology in term of stations only. In a
similar manner, the following variant of the same command shows the
model in terms of nodes, which corresponds to the internal
representation within <span class="smallcaps">Line</span>.

    [~,H] = model.getGraph();
    plot(H,'EdgeLabel',H.Edges.Weight,'Layout','Layered')

The next figures shows the difference between the two commands for an
open queueing network with two classes and class-switching. Weights on
the edges correspond to routing probabilities. In the station topology
on the left, note that since the `Sink` node is not a station,
departures to the `Sink` are drawn as returns to the `Source`. The node
topology on the right, illustrates all nodes, including certain
`ClassSwitch` nodes that are automatically added by
<span class="smallcaps">Line</span> to apply the class-switching routing
strategy. Double arcs between nodes indicate that both classes are
routed to the destination.

![`getGraph` function: station topology (left) and node topology (right)
for a 2-class tandem queueing network with
class-switching.](./images/getGraph_Stations.png) ![`getGraph` function:
station topology (left) and node topology (right) for a 2-class tandem
queueing network with class-switching.](./images/getGraph_Nodes.png)

<span id="FIG_getGraph" label="FIG_getGraph">\[FIG\_getGraph\]</span>

Furthermore, the graph properties concisely summarize the key features
of the network

    >> G.Nodes
    ans =
      2x5 table
          Name            Type           Sched    Jobs    ClosedClass1
        ________    _________________    _____    ____    ____________
        'Delay'     'Delay'       'inf'     5           1
        'Queue1'    'Queue'    'ps'      0           2
    >> G.Edges
    ans =
      3x4 table
              EndNodes          Weight    Rate        Class
        ____________________    ______    ____    ______________
        'Delay'     'Delay'      0.7        1     'ClosedClass1'
        'Delay'     'Queue1'     0.3        1     'ClosedClass1'
        'Queue1'    'Delay'        1      0.5     'ClosedClass1'

Here, `Edge.Weight` is the routing probability between the nodes,
whereas `Edge.Rate` is the service rate of the source node.

## Model import and export

<span class="smallcaps">Line</span> offers a number of scripts to import
external models into `Network` object instances that can be analyzed
through its solvers. The available scripts are as follows:

  - `JMT2LINE` imports a JMT simulation model (`.jsimg` or `.jsimw`
    file) instance.

  - `PMIF2LINE` imports a XML file containing a PMIF 1.0 model.

Both scripts require in input the filename and desired model name, and
return a single output,
    e.g.,

    qn = PMIF2LINE([pwd,'examplesdataPMIFpmif_example_closed.xml'],'Mod1')

where `qn` is an instance of the `Network` class.

`Network` object can be saved in binary `.mat` files using MATLAB’s
standard `save` command. However, it is also possible to export a
textual script that will dynamically recreate the same `Network` object.
For example,

    example_closedModel_1; LINE2SCRIPT(model, 'script.m')

creates a new file `script.m` with code

    model = Network('model');
    queue = Delay(model, 'Delay');
    delay = Queue(model, 'Queue1', SchedStrategy.PS);
    delay.setNumServers(1);
    class1 = ClosedClass(model, 'ClosedClass1', 5, queue, 0);
    queue.setService(class1, Cox2.fitMeanAndSCV(1.000000,1.000000));
    delay.setService(class1, Cox2.fitMeanAndSCV(2.000000,1.000000));
    P = cell(1);
    P{1,1} = [0.7 0.3;1 0];
    model.link(P);

that is equivalent to the model specified in `example_closedModel_1.m`.

### Creating a <span class="smallcaps">Line</span> model using JMT

Using the features presented in the previous section, one can create a
model in JMT and automatically derive a corresponding
<span class="smallcaps">Line</span> script from it. For instance, the
following command performs the import and translation into a script,
e.g.,

    LINE2SCRIPT(JMT2LINE('myModel.jsimg'),'myModel.m')

transforms and save the given JSIMgraph model into a corresponding
<span class="smallcaps">Line</span> model.

<span class="smallcaps">Line</span> also gives two static functions to
inspect `jsimg` and `jsimw` files before conversion, i.e.,
`SolverJMT.jsimgOpen` and `SolverJMT.jsimwOpen` require as an input
parameter only the JMT file name, e.g., ’myModel.jsimg’.
