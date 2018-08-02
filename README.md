## LINE: Performance and Reliability Analysis Engine

Current version: 2.0.0-ALPHA1 (BSD-3 License)

URL: https://github.com/line-solver/line

LINE is a MALAB toolbox for performance and reliability analysis of systems and processes that can be modeled using queueing theory. The engine offers a rich language to specify queueing models and decouples the model description from the solvers used for its solution. This is done through model-to-model transformations that automatically translate the model specification into the input format (or data structure) accepted by the target solver.

Supported models include *extended queueing networks*, both open and closed, and *layered queueing networks*. Models can be solved with either external solvers or native solvers. Wrappers are integrated in LINE that are able to invoke external solvers such as [JMT](http://jmt.sourceforge.net/) and [LQNS](http://www.sce.carleton.ca/rads/lqns/lqn-documentation/) and transparently import back their results in LINE format. Native model solvers written in the MATLAB language are also integrated. They are based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), normalizing constant analysis, and approximate mean-value analysis (AMVA). 

### Getting started

To get started, either clone the repository ([dev release](https://github.com/line-solver/line)) or uncompress the latest archive ([stable release](https://github.com/line-solver/line/releases)) in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```

### Documentation
Detailed guidance on how to use LINE is provided in the [User Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf).

### References

To cite LINE, please refer to the following article: J. F. Pérez and G. Casale, "LINE: Evaluating Software Applications in Unreliable Environments", IEEE Transactions on Reliability, 66(3), pp. 837 - 853, Sept 2017. Online: [IEEE Xplore](http://ieeexplore.ieee.org/document/7843645/).

The development of LINE has been partially funded by the European Commission grants FP7-318484 (MODAClouds), H2020-644869 (DICE), and by the EPSRC grant EP/M009211/1 (OptiMAM).
