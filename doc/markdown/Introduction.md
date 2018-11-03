## Table of Contents 
[**Introduction**](https://github.com/line-solver/line/wiki/Introduction)
- [What is <span class="smallcaps">Line</span>?](https://github.com/line-solver/line/wiki/Introduction#what-is-line)
- [Obtaining the latest release](https://github.com/line-solver/line/wiki/Introduction#obtaining-the-latest-release)
- [Installation and demos](https://github.com/line-solver/line/wiki/Introduction#installation-and-demos)
- [Getting help](https://github.com/line-solver/line/wiki/Introduction#getting-help)
- [References](https://github.com/line-solver/line/wiki/Introduction#references)
- [Contact](https://github.com/line-solver/line/wiki/Introduction#contact)
- [Copyright and license](https://github.com/line-solver/line/wiki/Introduction#copyright-and-license)
- [Acknowledgement](https://github.com/line-solver/line/wiki/Introduction#acknowledgement)

# Introduction

## What is <span class="smallcaps">Line</span>?

<span class="smallcaps">Line</span> is an engine for system performance
and reliability evaluation based on queueing theory and stochastic
modeling. Systems analyzed with <span class="smallcaps">Line</span> may
either be software applications, business processes, computer networks,
or else. <span class="smallcaps">Line</span> decomposes a high-level
system model into one or more stochastic models, typically extended
queueing networks, that are subsequently analyzed for performance and
reliability metrics using either numerical algorithms or simulation.

A key feature of <span class="smallcaps">Line</span> is that the engine
decouples the model description from the solvers used for its solution.
That is, the engine implements model-to-model transformations that
automatically translate the model specification into the input format
(or data structure) accepted by the target solver. External solvers
supported by <span class="smallcaps">Line</span> include Java Modelling
Tools (JMT; <http://jmt.sf.net>) and LQNS
(<http://www.sce.carleton.ca/rads/lqns/>). Native model solvers are
based on formalisms and techniques such as:

  - Continuous-time Markov chains (`CTMC`)

  - Fluid ordinary differential equations (`FLUID`)

  - Matrix analytic methods (`MAM`)

  - Normalizing constant analysis (`NC`)

  - Mean-value analysis (`MVA`)

  - Stochastic simulation (`SSA`)

Each solver encodes a general solution paradigm and can implement both
exact and approximate analysis methods. For example, the `MVA` solver
implements both exact mean value analysis (MVA) and approximate mean
value analysis (AMVA). The offered methods typically differ for
accuracy, computational cost, and the subset of model features they
support. A special solver (`AUTO`) is supplied that provides an
automated recommendation on which solver to use for a given model.

The above techniques can be applied to models specified in the following
formats:

  - <span>*<span class="smallcaps">Line</span> modeling language (MATLAB
    script format)*</span>. This is a MATLAB-based object-oriented
    language designed to resemble the abstractions available in JMT’s
    queueing network simulator (JSIM). Among the main benefits of this
    language is that <span class="smallcaps">Line</span> models can be
    exported to, and visualized with, JSIMgraph.

  - <span>*Layered queueing network models (LQNS XML format)*</span>.
    <span class="smallcaps">Line</span> is able to solve a sub-class of
    layered queueing network models, provided that they are specified
    using the XML metamodel of the LQNS solver.

  - <span>*JMT simulation models (JSIMg, JSIMw formats)*</span>.
    <span class="smallcaps">Line</span> is able to import and solve
    queueing network models specified using JMT’s simulation tools,
    namely JSIMgraph and JSIMwiz.

  - <span>*Performance Model Interchange Format (PMIF XML
    format)*</span>. <span class="smallcaps">Line</span> is able to
    import and solve closed queueing network models specified using PMIF
    v1.0.

## Obtaining the latest release

This document contains the user manual for
<span class="smallcaps">Line</span> version 2.0.0-ALPHA, which can be
obtained from:

<span><https://github.com/line-solver/line/></span>

<span class="smallcaps">Line</span> 2.0.0-ALPHA has been tested on
MATLAB R2017b and later releases and requires the *Statistics and
Machine Learning Toolbox*. If you are interested to obtain
<span class="smallcaps">Line</span> as a JAR, or as an executable
distribution for any of the operating systems supported by the MATLAB
Compiler Runtime (MCR), please contact the maintainer.

## Installation and demos

This is the fastest way to get started with
<span class="smallcaps">Line</span>:

1.  Download/clone the latest release:
    
      - Git repository: <https://github.com/line-solver/line/>
    
    Ensure that files are available in the chosen installation folder.

2.  Start MATLAB and change the active directory to the installation
    folder. Then add all sub-folders to the MATLAB path
    
        addpath(genpath(pwd))

3.  Run the demonstrators using
    
        allExamples

## Getting help

For bugs or feature requests, please use:
<https://github.com/line-solver/line/issues>

## References

To cite <span class="smallcaps">Line</span>, we recommend to reference:

  - J. F. Pérez and G. Casale. “LINE: Evaluating Software Applications
    in Unreliable Environments”, in <span>*IEEE Transactions on
    Reliability*</span>, Volume 66, Issue 3, pages 837-853, Feb 2017.
    <span>*This paper introduces <span class="smallcaps">Line</span>
    version 1.0.0*</span>.

The following papers discuss recent applications of
<span class="smallcaps">Line</span>:

  - C. Li and G. Casale. “Performance-Aware Refactoring of Cloud-based
    Big Data Applications”, in <span> Proceedings of 10th IEEE/ACM
    International Conference on Utility and Cloud Computing</span>,
    2017. <span>*This paper uses <span class="smallcaps">Line</span> to
    model stream processing systems*</span>.

  - D. J. Dubois, G. Casale. “OptiSpot: minimizing application
    deployment cost using spot cloud resources”, in <span>*Cluster
    Computing*</span>, Volume 19, Issue 2, pages 893-909, 2016.
    <span>*This paper uses <span class="smallcaps">Line</span> to
    determine bidding costs in spot VMs*</span>.

  - R. Osman, J. F. Pérez, and G. Casale. “Quantifying the Impact of
    Replication on the Quality-of-Service in Cloud Databases’.
    <span>Proceedings of the IEEE International Conference on Software
    Quality, Reliability and Security (QRS)</span>, 286-297, 2016.
    <span>*This paper uses <span class="smallcaps">Line</span> to model
    the Amazon RDS database*</span>.

  - C. M<span>ü</span>ller, P. Rygielski, S. Spinner, and S. Kounev.
    <span>Enabling Fluid Analysis for Queueing Petri Nets via Model
    Transformation</span>, <span>Electr. Notes Theor. Comput.
    Sci</span>, <span>327</span>, <span>71–91</span>, <span>2016</span>.
    <span>*This paper uses <span class="smallcaps">Line</span> to
    analyze Descartes models used in software engineering*</span>.

  - J. F. Pérez and G. Casale. “Assessing SLA compliance from Palladio
    component models,” in <span>Proceedings of the 2nd Workshop on
    Management of resources and services in Cloud and Sky computing
    (MICAS)</span>, IEEE Press, 2013. <span>*This paper uses
    <span class="smallcaps">Line</span> to analyze Palladio component
    models used in model-driven software engineering*</span>.

## Contact

Project coordinator and maintainer contact:

    Giuliano Casale
    Department of Computing
    Imperial College London
    180 Queen's Gate
    SW7 2AZ, London, UK.

`Web:` <http://wp.doc.ic.ac.uk/gcasale/>

## Copyright and license

Copyright Imperial College London (2015-Present).
<span class="smallcaps">Line</span> 2.0.0-ALPHA is freeware, but
closed-source, and released under the 3-clause BSD license. Additional
licensing information is available in the license file:
<https://raw.githubusercontent.com/line-solver/line/master/LICENSE>.
License files of third-party libraries are placed under the `lib/`
directory.

## Acknowledgement

<span class="smallcaps">Line</span> has been partially funded by the
European Commission grants FP7-318484 (MODAClouds), H2020-644869 (DICE),
and by the EPSRC grant EP/M009211/1 (OptiMAM).
