# LINE
LINE: Performance and Reliability Analysis Engine

Current version: 2.0.0-BETA1 (BSD-3 License)

URL: https://github.com/line-solver/line

LINE is a hybrid tool for performance and reliability analysis of complex systems based on queueing theory and stochastic modeling. The engine decouples the model description from the solvers used for its solution. The engine acts as a bridge between model and solvers, implementing model-to-model transformations that automatically translate the model specification into the input format or data structure accepted by the target solver.

Supported models include extended queueing networks, both open and closed, and layered queueing networks. Wrappers are integrated in LINE to transparently use external solvers such as [JMT](http://jmt.sourceforge.net/) and [LQNS/LQSIM](http://www.sce.carleton.ca/rads/lqns/lqn-documentation/). LINE also features several native model solvers written in MATLAB and based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), and approximate mean-value analysis (AMVA). 

To get started, clone the repository. Alternatevily, you can download the latest release from the [Releases](https://github.com/line-solver/line/releases) page and unzip the file in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```
Detailed guidance on how to use the engine is provided in the [LINE Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf).
