## Table of Contents 
[**Random environments**](https://github.com/line-solver/line/wiki/Environments#random-environments)
- [Environment object definition](https://github.com/line-solver/line/wiki/Environments#environment-object-definition)
   - [Specifying the environment transitions](https://github.com/line-solver/line/wiki/Environments#specifying-the-environment-transitions)
   - [Specifying the system models](https://github.com/line-solver/line/wiki/Environments#specifying-the-system-models)
- [Solvers](https://github.com/line-solver/line/wiki/Environments#solvers)
   - [`ENV`](https://github.com/line-solver/line/wiki/Environments#env)

# Random environments

Systems modeled with <span class="smallcaps">Line</span> can be
described as operating in an environment whose state affects the way the
system operates. To distinguish the states of the environment from the
ones of the system within it, we shall refer to the former as the
environment <span>*stages*</span>. In particular,
<span class="smallcaps">Line</span> 2.0.0-ALPHA supports the definition
of a class of random environments subject to three assumptions:

  - The stage of the environment evolves independently of the state of
    the system.

  - The dynamics of the environment stage can be described by a
    continuous-time Markov chain.

  - The topology of the system is independent of the environment stage.

The above definitions are in particular appropriate to describe systems
whose input parameters change with the environment stage. For example,
an environment with two stages, say normal load and peak load, may
differ for the number of servers that are available in a queueing
station, i.e., the system controller may add more servers during peak
load. Upon a stage change in the environment, the model parameters will
instantaneously change, but the state reached during the previous stage
will be used to initialize the system in the new stage.

Although in a number of cases the system performance may be similar to a
weighted combination of the average performance in each stage, this is
not true in general, especially if the system dynamic (i.e., the rate at
which jobs arrived and get served) and the environment dynamic (i.e.,
the rate at which the environment changes active stage) happen at
similar timescales \[[Casale et al. 2014](https://dl.acm.org/citation.cfm?id=2943698)\].

## Environment object definition

### Specifying the environment transitions

To specify an environment, it is sufficient to define a cell array with
entries describing the distribution of time before the environment jumps
to a given target state. For example

    env{1,1} = Exp(0);
    env{1,2} = Exp(1);
    env{2,1} = Exp(1);
    env{2,2} = Exp(0);

describes an environment consisting of two stage, where the time before
a transition to the other stage is exponential with unit rate. If we
were to set instead

    env{2,2} = Erlang.fitMeanAndOrder(1,2);

this would cause a race condition between two distributions in stage
two: the exponential transition back to stage 1, and the Erlang-2
distributed transition with unit rate that remains in stage 2. The
latter means that periodically the system will be re-initialized in
stage 2, meaning that jobs in execution at a server are required all to
restart execution.

In <span class="smallcaps">Line</span>, an environment is internally
described by a Markov renewal process (MRP) with transition times
belonging to the `PhaseType` class. A MRP is similar to a Markov chain,
but state transitions are not restricted to be exponential. Although the
time spent in each state of the MRP is not exponential, the MRP can be
easily transformed into an equivalent continuous-time Markov chain
(CTMC) to enable analysis, a task that
<span class="smallcaps">Line</span> performs automatically. In the
example above, the underpinning CTMC will therefore consider the
distribution of the minimum between the exponential and the Erlang-2
distribution, in order to decide the next stage transition.

State space explosion may occur in the definition of an environment if
the user specifies a large number of non-exponential transition. For
example, a race condition among n Erlang-2 distribution translates
at the level of the CTMC into a state space with 2^n states. In such
situations, it is recommended to replace some of the distributions with
exponential ones.

### Specifying the system models

<span class="smallcaps">Line</span> places loose assumptions in the way
the system should be described in each stage. It is just expected that
the user supplies a model object, either a `Network` or a
`LayeredNetwork`, in each stage, and that a transient analysis method is
available in the chosen solver, a requirement fulfilled for example by
`SolverFluid`.

However, we note that the model definition can be somewhat simplified if
the user describes the system model in a separate MATLAB function,
accepting the stage-specific parameters in input to the function. This
enables reuse of the system topology across stages, while creating
independent model objects. An example of this specification style is
given in `example_randomEnvironment_1.m` under
<span class="smallcaps">Line</span>’s example folder.

## Solvers

The steady-state analysis of a system in a random environment is carried
out in <span class="smallcaps">Line</span> using the blending
method \[[Casale et al. 2014](https://dl.acm.org/citation.cfm?id=2943698)\], which is an iterative algorithm leveraging the
transient solution of the model. In essence, the model looks at the
*average* state of the system at the instant of each stage transition,
and upon restarting the system in the new stage re-initializes it from
this average value. This algorithm is implemented in
<span class="smallcaps">Line</span> by the `SolverEnv` class, which is
described next.

### `ENV`

The `SolverEnv` class applies the blending algorithm by iteratively
carrying out a transient analysis of each system model in each
environment stage, and probabilistically weighting the solution to
extract the steady-state behavior of the system.

As in the transient analysis of `Network` objects,
<span class="smallcaps">Line</span> does not supply a method to obtain
mean response times, since Little’s law does not hold in the transient
regime. To obtain the mean queue-length, utilization and throughput of
the system one can call as usual the `getAvg` method on the `SolverEnv`
object, e.g.,

    models = {model1, model2, model3, model4};
    envSolver = SolverEnv(models, env, @SolverFluid,options);
    [QN,UN,TN] = envSolver.getAvg()

Note that as model complexity grows, the number of iterations required
by the blending algorithm to converge may grow large. In such cases, the
`options.iter_max` option may be used to bound the maximum analysis
time.
