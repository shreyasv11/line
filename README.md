# LINE
LINE: Performance and Reliability Analysis Engine.

Current version: 2.0.0-BETA1 (BSD-3 License)

URL: https://github.com/line-solver/line

LINE is a tool for performance and reliability analysis of complex systems based on queueing theory and stochastic modeling. Using LINE, it is possible to decouple the model description from the solvers used for its solution. A number of wrappers exist for external solvers such [JMT](http://jmt.sourceforge.net/) and [LQSIM](http://www.sce.carleton.ca/rads/lqns/lqn-documentation/lqsim.txt), as well-as native LINE solvers based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, and approximate mean-value analysis (AMVA). 

To get started, clone the repository or download the latest release from the [Releases](https://github.com/line-solver/line/releases) page. Unzip the file in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```
Guidance on how to use the engine is provided in the [LINE Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf).
