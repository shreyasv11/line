## LINE: Performance and Reliability Analysis Engine

Current version: 2.0.0-ALPHA (BSD-3 License)

URL: https://github.com/line-solver/line

LINE is a MATLAB toolbox for performance and reliability analysis of systems and processes that can be modeled using queueing theory. The engine offers a rich language to specify queueing networks that decouples model description from the solvers used for numerical solution. This is done through model-to-model transformations that automatically translate the model specification into the input format (or data structure) accepted by the target solver.

Supported models include *extended queueing networks*, both open and closed, and *layered queueing networks*. Models can be solved with either native or external solvers, the latter include [JMT](http://jmt.sourceforge.net/) and [LQNS](http://www.sce.carleton.ca/rads/lqns/lqn-documentation/). Native solvers are based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), normalizing constant analysis, and mean-value analysis (MVA). 

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
Detailed instructions on how to use LINE are provided in the [User Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf).

### Acknowledgement
The development of LINE has been partially funded by the European Commission grants FP7-318484 ([MODAClouds](http://multiclouddevops.com/)), H2020-644869 ([DICE](http://www.dice-h2020.eu/)), and by the EPSRC grant EP/M009211/1 ([OptiMAM](https://wp.doc.ic.ac.uk/optimam/)).
