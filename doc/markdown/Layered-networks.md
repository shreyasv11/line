## Table of Contents 
[**Layered network models**](https://github.com/line-solver/line/wiki/Layered-networks#layered-network-models)
- [LayeredNetwork object definition](https://github.com/line-solver/line/wiki/Layered-networks#layerednetwork-object-definition)
   - [Creating a layered network topology](https://github.com/line-solver/line/wiki/Layered-networks#creating-a-layered-network-topology)
   - [Describing service times of entries](https://github.com/line-solver/line/wiki/Layered-networks#describing-service-times-of-entries)
      - [Activity graphs](https://github.com/line-solver/line/wiki/Layered-networks#activity-graphs)
   - [Debugging and visualization](https://github.com/line-solver/line/wiki/Layered-networks#debugging-and-visualization)
- [Decomposition into layers](https://github.com/line-solver/line/wiki/Layered-networks#decomposition-into-layers)
   - [Running a decomposition](https://github.com/line-solver/line/wiki/Layered-networks#running-a-decomposition)
   - [Initialization and update](https://github.com/line-solver/line/wiki/Layered-networks#initialization-and-update)
- [Solvers](https://github.com/line-solver/line/wiki/Layered-networks#solvers)
   - [`LQNS`](https://github.com/line-solver/line/wiki/Layered-networks#lqns)
   - [`LN`](https://github.com/line-solver/line/wiki/Layered-networks#ln)
- [Model import and export](https://github.com/line-solver/line/wiki/Layered-networks#model-import-and-export)

# Layered network models

In this chapter, we present the definition of the `LayeredNetwork`
class, which encodes the support in <span class="smallcaps">Line</span>
for layered queueing networks. These models are extended queueing
networks where servers, in order to process jobs, can issue synchronous
and asynchronous calls among each other. The topology of call
dependencies makes it possible to partition the model into a set of
layers, each consisting of a subset of the resources.

## LayeredNetwork object definition

### Creating a layered network topology

A layered queueing network consists of four types of elements:
processors, tasks, entries and activities. An entry is a class of
service specified through a finite sequence of activities, and hosted by
a task running on a (physical) processor. A task is typically a software
queue that models access to the capacity of the underpinning processor.
Activities model either service demands required at the underpinning
processor, or calls to entries exposed by some remote tasks.

To create our first layered network, we instantiate a new model as

    model = LayeredNetwork('myLayeredModel');

We now proceed to instantiate the static topology of processors, tasks
and entries:

    P1 = Processor(model, 'P1', 1, SchedStrategy.PS);
    P2 = Processor(model, 'P2', 1, SchedStrategy.PS);
    T1 = Task(model, 'T1', 5, SchedStrategy.REF).on(P1);
    T2 = Task(model, 'T2', 1, SchedStrategy.INF).on(P2);
    E1 = Entry(model, 'E1').on(T1);
    E2 = Entry(model, 'E2').on(T2);

Here, the `on` method specifies the associations between the elements,
e.g., task `T1` runs on processor `P1`, and accepts calls to entry `E1`.
Furthermore, the multiplicity of `T1` is 5, meaning that up to 5 calls
can be simultaneously served by this element (i.e., 5 is the number of
servers in the underpinning queueing system for `T1`). Note that both
processors and tasks can be associated to the standard
<span class="smallcaps">Line</span> scheduling strategies, with the
exception that `SchedStrategy.REF` should be used to denote the
reference task, which has a similar meaning to the reference node in the
`Network` object.

### Describing service times of entries

The service demands placed by an entry on the underpinning processor is
described in terms of execution of one or more activities. Although in
tools such as LQNS activities can be associated to either entries or
tasks, <span class="smallcaps">Line</span> supports only the more
general of the two options, i.e., the definition of activities of the
level of tasks. In this case:

  - Every task defines a collection of activities.

  - Every entry needs to specify an initial activity where the execution
    of the entry starts (the activity is said to be “bound to the
    entry”) and a final activity, which upon completion terminates the
    execution of the entry.

For example, we can associate an activity to each entry as
    follows:

    A1 = Activity(model, 'A1', Exp(1.0)).on(T1).boundTo(E1).synchCall(E2,3.5);
    A2 = Activity(model, 'A2', Exp(2.0)).on(T2).boundTo(E2).repliesTo(E2);

Here, `A1` is a task activity for `T1`, acts as initial activity for
`E1`, consumes an exponential distributed time on the processor
underpinning `T1`, and requires on average 3.5 synchronous calls to `E2`
to complete. Each call to entry `E2` is served by the activity `A2`,
with a service time on the processor underneath `T2` given by an
exponential distribution with rate lambda=2.0.

At present, <span class="smallcaps">Line</span> 2.0.0-ALPHA supports
only synchronous calls. Support for asynchronous calls is available in
older versions, e.g. <span class="smallcaps">Line</span> 1.0.0.
Extension of <span class="smallcaps">Line</span> 2.0.0-ALPHA to
asynchronous calls

#### Activity graphs

Often, it is useful to structure the sequence of activities carried out
by an entry in a graph. Currently, <span class="smallcaps">Line</span>
supports this feature only for activities places in series. For example,
we may replace the specification of the activities underpinning a call
to `E2` as

    A20 = Activity(model, 'A20', Exp(1.0)).on(T2).boundTo(E2);
    A21 = Activity(model, 'A21', Erlang.fitMeanAndOrder(1.0,2)).on(T2);
    A22 = Activity(model, 'A22', Exp(1.0)).on(T2).repliesTo(E2);
    T2.addPrecedence(ActivityPrecedence.Serial(A20, A21, A22));

such that a call to `E2` serially executes `A20`, `A21`, and `A22` prior
to replying. Here, `A21` is chosen to be an Erlang distribution with
given mean (1.0) and number of phases (2).

### Debugging and visualization

The structure of a `LayeredNetwork` object can be graphically visualized
as follows

    plot(model)

An example of the result is shown in the next figure. The figure shows
two processors (`P1` and `P2`), two tasks (`T1` and `T2`), and three
entries (`E1`, `E2`, and `E3`) with their associated activities. Both
dependencies and calls are both shown as directed arcs, with the edge
weight on call arcs corresponding to the average number of calls to the
target entry. For example, `A1` calls `E3` on average 2.0 times.

![`LayeredNetwork.plot` method](./images/lqnView.png)

<span id="FIG_lqnView" label="FIG_lqnView">\[FIG\_lqnView\]</span>

As in the case of the `Network` class, the `getGraph` method can be
called to inspect the structure of the `LayeredNetwork` object.

Lastly, the `jsimgView` and `jsimwView` methods can be used to visualize
in JMT each layer. This can be done by first calling the `getLayers`
method to obtain a cell array consisting of the `Network` objects, each
one corresponding to a layer, and then invoking the `jsimgView` and
`jsimwView` methods on the desired layer. This is discussed in more
details in the next section.

## Decomposition into layers

Layers are a form of decomposition where the influence of resources not
explicitly represented in that layer is taken into account through an
artificial delay station, placed in a closed loop to the
resources \[[Rolia et al. 1995](https://dl.acm.org/citation.cfm?id=631178)\]. This artificial delay is used to model the
inter-arrival time between calls from resources that belong to other
layers.

### Running a decomposition

The current version of <span class="smallcaps">Line</span> adopts
SRVN-type layering \[[LQNSUserMan](http://www.sce.carleton.ca/rads/lqns/LQNSUserMan.pdf)\], whereby a layer corresponds to one and
only one resource, either a processor or a task. The only exception are
reference tasks, which can only appear as clients to their processors.
The `getLayers` method returns a cell array consisting of the `Network`
objects corresponding to each layer

    layers = model.getLayers()

Within each layer, classes are used to model the time a job spends in a
given activity or call, with synchronous calls being modeled by classed
with label including an arrow, e.g., `’AS1=>E3’` is a closed class used
represent synchronous calls from activity `AS1` to entry `E3`.
Artificial delays and reference nodes are modelled as a delay station
named `’Clients’`, whereas the task or processor assigned to the layer
is modelled as the other node in the layer.

### Initialization and update

In general, the parameters of a layer will depend on the steady-state
solution of an other layer, causing a cyclic dependence that can be
broken only after the model is analyzed by a solver. In order to assign
parameters within each layer prior to its solution, the `LayeredNetwork`
class uses the `initDefault` method, which sets the value of the
artificial delay to simple operational analysis bounds \[[Lazwoska et al. 1984](https://homes.cs.washington.edu/~lazowska/qsp/)\].

The layer parameterization depends on a subset of performance indexes
stored in a `param` structure array within the `LayeredNetwork` class.
After initialization, it is possible to update the layer
parameterization for example as follows

    layers = model.getLayers();
    for l=1:model.getNumberOfLayers()
        AvgTableByLayer{l} = SolverMVA(layers{l}).getAvgTable;
    end
    model.updateParam(AvgTableByLayer);
    model.refreshLayers;

Here, the `refreshParam` method updates the `param` structure array from
a cell array of steady-state solutions for the `Network` objects in each
layer. Subsequently, the `refreshLayers` method enacts the new
parameterization across the `Network` objects in each layer.

## Solvers

<span class="smallcaps">Line</span> offers two solvers for the solution
of a `LayeredNetwork` model consisting in its own native solver (`LN`)
and a wrapper (`LQNS`) to the LQNS solver \[[LQNSUserMan](http://www.sce.carleton.ca/rads/lqns/LQNSUserMan.pdf)\]. The latter
requires a distribution of LQNS to be available on the operating system
command line.

The solution methods available for `LayeredNetwork` models are similar
to those for `Network` objects. For example, the `getAvgTable` can be
used to obtain a full set of mean performance indexes for the model,
e.g.,

    >> AvgTable = SolverLQNS(model).getAvgTable
    AvgTable =
      8x6 table
        Node     NodeType       QLen        Util      RespT      Tput
        ____    ___________    _______    ________    _____    ________
        'P1'    'Processor'        NaN    0.071429     NaN          NaN
        'T1'    'Task'         0.28571    0.071429     NaN     0.071429
        'E1'    'Entry'        0.28571    0.071429       4     0.071429
        'A1'    'Activity'     0.28571    0.071429       4     0.071429
        'P2'    'Processor'        NaN     0.21429     NaN          NaN
        'T2'    'Task'         0.21429     0.21429     NaN      0.21429
        'E2'    'Entry'        0.21429     0.21429       1      0.21429
        'A2'    'Activity'     0.21429     0.21429       1      0.21429

Note that in the above table, some performance indexes are marked as
`NaN` because they are not defined in a layered queueing network.
Further, compared to the `getAvgTable` method in `Network` objects,
`LayeredNetwork` do not have an explicit differentiation between
stations and classes, since in a layer a task may either act as a server
station or a client class.

The main challenge in solving layered queueing networks through
analytical methods is that the parameterization of the artificial delays
depends on the steady-state performance of the other layers, thus
causing a cyclic dependence between input parameters and solutions
across the layers. Depending on the solver in use, such issue can be
addressed in a different way, but in general a decomposition into layers
will remain parametric on a set of response times, throughputs and
utilizations.

This issue can be resolved through solvers that, starting from an
initial guess, cyclically analyze the layers and update their artificial
delays on the basis of the results of these analyses. Both `LN` and
`LQNS` implement this solution method. Normally, after a number of
iterations the model converges to a steady-state solution, where the
parameterization of the artificial delays does not change after
additional iterations.

### `LQNS`

The LQNS wrapper operates by first transforming the specification into a
valid LQNS XML file. Subsequently, LQNS calls the solver and parses the
results from disks in order to present them to the user in the
appropriate <span class="smallcaps">Line</span> tables or vectors. The
`options.method` can be used to configure the LQNS execution as follows:

  - `options.method=’std’` or `’lqns’`: LQNS analytical solver with
    default settings.

  - `options.method=’exact’`: the solver will execute the standard LQNS
    analytical solver with the exact MVA method.

  - `options.method=’srvn’`: LQNS analytical solver with SRVN layering.

  - `options.method=’srvnexact’`: the solver will execute the standard
    LQNS analytical solver with SRVN layering and the exact MVA method.

  - `options.method=’lqsim’`: LQSIM simulator, with simulation length
    specified via the `samples` field (i.e., with parameter `-A
    options.samples, 0.95`).

Upon invocation, the `lqns` or `lqsim` commands will be searched for in
the system path. If they are unavailable, the termination of
`SolverLQNS` will interrupt.

### `LN`

The native `LN` solver iteratively applies the layer updates until
convergence of the steady-state measures. Since updates are parametric
on the solution of each layer, `LN` can apply any of the `Network`
solvers described in the solvers chapter to the analysis of individual
layers, as illustrated in the following example for the `MVA` solver

    options = SolverLN.defaultOptions;
    mvaopt = SolverMVA.defaultOptions;
    SolverLN(model, @(layer) SolverMVA(layer, mvaopt), options).getAvgTable

Options parameters may also be omitted. The `LN` method converges when
the maximum relative change of mean response times across layers from
the last iteration is less than `options.iter_tol`.

## Model import and export

A `LayeredNetwork` can be easily read from, or written to, a XML file
based on the LQNS meta-model format\[1\]. The read operation can be done
using a static method of the `LayeredNetwork` class, i.e.,

    model = LayeredNetwork.parseXML(filename)

Conversely, the write operation is invoked directly on the model object

    model.writeXML(filename)

In both examples, `filename` is a string including both file name and
its path.

Finally, we point out that it is possible to export a LQN in the legacy
SRVN file format\[2\] by means of the `writeSRVN(filename)`
    function.

1.  <https://raw.githubusercontent.com/layeredqueuing/V5/master/xml/lqn.xsd>

2.  <http://www.sce.carleton.ca/rads/lqns/lqn-documentation/format.pdf>
